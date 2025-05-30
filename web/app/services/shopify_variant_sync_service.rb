# Servicio para sincronizar variantes de productos y sus niveles de inventario desde Shopify
# Este servicio utiliza la API GraphQL de Shopify para obtener datos actualizados
# y mantener sincronizada la base de datos local con Shopify
class ShopifyVariantSyncService
  # Error personalizado para manejar excepciones específicas de sincronización
  class SyncError < StandardError; end

  # Consulta GraphQL para obtener información detallada de variantes
  # La query está estructurada para obtener:
  # 1. Información básica de la variante:
  #    - id: Identificador único de la variante en Shopify
  #      → Variant.shopify_variant_id
  #    - title: Título de la variante
  #      → Variant.variant_title
  # 2. Información del item de inventario:
  #    - id: Identificador único del item de inventario
  #      → InventoryLevel.shopify_inventory_item_id
  #    - tracked: Indica si el inventario está siendo rastreado
  #      → Variant.is_tracked
  #    - display_name: Nombre para mostrar del item
  #      → No se utiliza actualmente en nuestros modelos ?
  # 3. Niveles de inventario por ubicación:
  #    - id: Identificador único del nivel de inventario
  #      → No se utiliza actualmente en nuestros modelos ?
  #    - quantities: Array con la cantidad disponible para venta
  #      * available: Cantidad disponible para venta
  #        → InventoryLevel.quantity
  #    - location: Información de la ubicación
  #      * id: Identificador único de la ubicación
  #        → Location.shopify_location_id
  #      * name: Nombre de la ubicación
  #        → Location.name
  # 4. Información del producto padre:
  #    - id: Identificador único del producto
  #      → Variant.shopify_product_id
  QUERY = <<~GRAPHQL
    query getVariantsStock($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on ProductVariant {
          id
          title
          inventoryItem {
            id
            tracked
            display_name
            inventoryLevels(first: 250) {
              edges {
                node {
                  id
                  quantities(names: ["available"]) {
                    name
                    quantity
                  }
                  location { 
                    id 
                    name 
                  }
                }
              }
            }
          }
          product { id }
        }
      }
    }
  GRAPHQL

  # Inicializa el servicio con una tienda de Shopify
  # @param shop [Shop] Instancia de la tienda de Shopify
  # @raise [SyncError] Si hay un error al inicializar el cliente GraphQL
  def initialize(shop)
    @shop = shop
    @logger = Rails.logger
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: shop.shopify_api_session)
  rescue StandardError => e
    @logger.error("Error initializing ShopifyVariantSyncService: #{e.message}")
    raise SyncError, "Failed to initialize sync service: #{e.message}"
  end

  # Sincroniza las variantes especificadas y sus niveles de inventario
  # Este método es el punto de entrada principal para la sincronización
  # @param variant_ids [Array<String>] Array de IDs de variantes de Shopify a sincronizar
  # @raise [SyncError] Si hay un error durante la sincronización
  def sync_variants!(variant_ids)
    validate_variant_ids!(variant_ids)
    
    @logger.info("Starting sync for #{variant_ids.size} variants")
    start_time = Time.current

    resp = fetch_variants_data(variant_ids)
    process_variants_data(resp.data.nodes)

    @logger.info("Sync completed in #{Time.current - start_time} seconds")
  rescue StandardError => e
    @logger.error("Sync failed: #{e.message}")
    raise SyncError, "Failed to sync variants: #{e.message}"
  end

  private

  # Valida que los IDs de variantes sean válidos
  # @param variant_ids [Array] Array de IDs a validar
  # @raise [SyncError] Si los IDs no son válidos
  def validate_variant_ids!(variant_ids)
    return if variant_ids.is_a?(Array) && variant_ids.any?

    raise SyncError, "Invalid variant_ids: must be a non-empty array"
  end

  # Ejecuta la consulta GraphQL para obtener datos de las variantes
  # @param variant_ids [Array<String>] IDs de variantes a consultar
  # @return [GraphQL::Client::Response] Respuesta de la consulta GraphQL
  # @raise [SyncError] Si la consulta falla
  def fetch_variants_data(variant_ids)
    @client.query(
      query: QUERY,
      variables: { ids: variant_ids }
    )
  rescue StandardError => e
    @logger.error("GraphQL query failed: #{e.message}")
    raise SyncError, "Failed to fetch variants data: #{e.message}"
  end

  # Procesa los datos de variantes obtenidos de Shopify
  # Este método itera sobre cada variante y procesa sus datos en una transacción
  # @param nodes [Array<OpenStruct>] Nodos de respuesta GraphQL
  # @raise [SyncError] Si hay un error al procesar los datos
  def process_variants_data(nodes)
    nodes.each do |node|
      next unless node.is_a?(OpenStruct)

      ActiveRecord::Base.transaction do
        variant = process_variant(node)
        process_inventory_levels(node, variant)
      end
    rescue StandardError => e
      @logger.error("Failed to process variant #{node.id}: #{e.message}")
      raise SyncError, "Failed to process variant: #{e.message}"
    end
  end

  # Procesa y actualiza una variante individual
  # @param node [OpenStruct] Datos de la variante de Shopify
  # @return [Variant] Variante actualizada o creada
  def process_variant(node)
    variant = Variant.find_or_initialize_by(shopify_variant_id: node.id)
    variant.assign_attributes(
      shop_id: @shop.id,
      shopify_product_id: node.product.id,
      variant_title: node.title,
      is_tracked: node.inventoryItem.tracked
    )
    variant.save!
    variant
  end

  # Procesa los niveles de inventario para una variante
  # Este método itera sobre cada nivel de inventario y actualiza o crea los registros correspondientes
  # @param node [OpenStruct] Datos de la variante de Shopify
  # @param variant [Variant] Variante local
  def process_inventory_levels(node, variant)
    node.inventoryItem.inventoryLevels.edges.each do |edge|
      lvl = edge.node
      location = find_or_create_location(lvl.location)
      
      # Encontrar la cantidad disponible en el array de quantities
      available_quantity = lvl.quantities.find { |q| q.name == 'available' }&.quantity || 0
      
      update_inventory_level(variant, location, lvl, node.inventoryItem.id, available_quantity)
    end
  end

  # Encuentra o crea una ubicación basada en los datos de Shopify
  # @param location_data [OpenStruct] Datos de ubicación de Shopify
  # @return [Location] Ubicación local
  def find_or_create_location(location_data)
    Location.find_or_create_by!(
      shop_id: @shop.id,
      shopify_location_id: location_data.id
    ) do |loc|
      loc.name = location_data.name
      loc.is_active = true
    end
  end

  # Actualiza o crea un nivel de inventario
  # Este método maneja la lógica de actualización de los niveles de inventario,
  # incluyendo el cálculo del porcentaje de salud
  # @param variant [Variant] Variante local
  # @param location [Location] Ubicación local
  # @param level_data [OpenStruct] Datos de nivel de inventario de Shopify
  # @param inventory_item_id [String] ID del item de inventario de Shopify
  # @param available_quantity [Integer] Cantidad disponible
  def update_inventory_level(variant, location, level_data, inventory_item_id, available_quantity)
    il = InventoryLevel.find_or_initialize_by(
      variant_id: variant.id,
      location_id: location.id
    )

    minimum_quantity = il.minimum_quantity || 0
    health_percentage = calculate_health_percentage(available_quantity, minimum_quantity)

    il.assign_attributes(
      quantity: available_quantity,
      minimum_quantity: minimum_quantity,
      health_percentage: health_percentage,
      shopify_inventory_item_id: inventory_item_id
    )
    il.save!
  end

  # Calcula el porcentaje de salud del inventario
  # La fórmula es: ((cantidad_disponible - cantidad_mínima) / cantidad_mínima) * 100
  # Si la cantidad mínima es 0, retorna 0.0
  # @param available [Integer] Cantidad disponible
  # @param minimum_quantity [Integer] Cantidad mínima requerida
  # @return [Float] Porcentaje de salud (0.0 si minimum_quantity es 0)
  def calculate_health_percentage(available, minimum_quantity)
    return 0.0 if minimum_quantity.zero?
    
    ((available - minimum_quantity).to_f / minimum_quantity * 100).round(2)
  end
end 