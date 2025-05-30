# Servicio para sincronizar variantes de productos y sus niveles de inventario desde Shopify
# Este servicio utiliza la API GraphQL de Shopify para obtener datos actualizados
# y mantener sincronizada la base de datos local con Shopify
class ShopifyVariantSyncService
  # Error personalizado para manejar excepciones específicas de sincronización
  class SyncError < StandardError; end

  # Consulta GraphQL para obtener información detallada de variantes
  # Incluye:
  # - Información básica de la variante (id, título)
  # - Estado de seguimiento del inventario
  # - Niveles de inventario por ubicación
  # - ID del producto padre
  QUERY = <<~GRAPHQL
    query getVariantsStock($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on ProductVariant {
          id
          title
          inventoryItem {
            tracked
            inventoryLevels(first: 250) {
              edges {
                node {
                  available
                  location { id name }
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
      is_tracked: node.inventoryItem.tracked,
      minimum_quantity: variant.minimum_quantity || 0
    )
    variant.save!
    variant
  end

  # Procesa los niveles de inventario para una variante
  # @param node [OpenStruct] Datos de la variante de Shopify
  # @param variant [Variant] Variante local
  def process_inventory_levels(node, variant)
    node.inventoryItem.inventoryLevels.edges.each do |edge|
      lvl = edge.node
      location = find_or_create_location(lvl.location)
      update_inventory_level(variant, location, lvl, node.inventoryItem.id)
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
  # @param variant [Variant] Variante local
  # @param location [Location] Ubicación local
  # @param level_data [OpenStruct] Datos de nivel de inventario de Shopify
  # @param inventory_item_id [String] ID del item de inventario de Shopify
  def update_inventory_level(variant, location, level_data, inventory_item_id)
    il = InventoryLevel.find_or_initialize_by(
      variant_id: variant.id,
      location_id: location.id
    )

    minimum_quantity = il.minimum_quantity || variant.minimum_quantity
    health_percentage = calculate_health_percentage(level_data.available, minimum_quantity)

    il.assign_attributes(
      quantity: level_data.available,
      minimum_quantity: minimum_quantity,
      health_percentage: health_percentage,
      shopify_inventory_item_id: inventory_item_id
    )
    il.save!
  end

  # Calcula el porcentaje de salud del inventario
  # @param available [Integer] Cantidad disponible
  # @param minimum_quantity [Integer] Cantidad mínima requerida
  # @return [Float] Porcentaje de salud (0.0 si minimum_quantity es 0)
  def calculate_health_percentage(available, minimum_quantity)
    return 0.0 if minimum_quantity.zero?
    
    ((available - minimum_quantity).to_f / minimum_quantity * 100).round(2)
  end
end 