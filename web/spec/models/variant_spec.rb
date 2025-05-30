# frozen_string_literal: true

require 'rails_helper'

# Suite de pruebas para el modelo Variant
# Este modelo representa una variante de producto en Shopify, que puede tener diferentes
# opciones (como color, talla, etc.) y está asociada a un producto específico
RSpec.describe Variant, type: :model do
  # Configuración de datos de prueba comunes
  let(:shop) { create(:shop) }
  
  # Instancia válida de Variant para usar en las pruebas
  # Incluye todos los atributos necesarios para una variante válida
  let(:valid_variant) do
    described_class.new(
      shop: shop,
      shopify_product_id: 'gid://shopify/Product/123456789',
      shopify_variant_id: 'gid://shopify/ProductVariant/987654321',
      variant_title: "Azul / S",
      display_name: "Camiseta Surf - Azul / S",
      is_tracked: true
    )
  end

  # Pruebas de validaciones del modelo
  describe 'validations' do
    # Verifica que una variante con todos los atributos válidos sea válida
    it 'is valid with valid attributes' do
      expect(valid_variant).to be_valid
    end

    # Verifica que se requiera un ID de producto de Shopify
    it 'requires shopify_product_id' do
      valid_variant.shopify_product_id = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:shopify_product_id]).to include("can't be blank")
    end

    # Verifica que se requiera un ID de variante de Shopify
    it 'requires shopify_variant_id' do
      valid_variant.shopify_variant_id = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:shopify_variant_id]).to include("can't be blank")
    end

    # Verifica que el ID de variante de Shopify sea único
    it 'requires unique shopify_variant_id' do
      valid_variant.save!
      duplicate_variant = valid_variant.dup
      expect(duplicate_variant).not_to be_valid
      expect(duplicate_variant.errors[:shopify_variant_id]).to include('has already been taken')
    end

    # Verifica que se requiera un título de variante
    it 'requires variant_title' do
      valid_variant.variant_title = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:variant_title]).to include("can't be blank")
    end

    # Pruebas específicas para el campo display_name
    describe 'display_name' do
      # Verifica que se requiera un nombre para mostrar
      it 'requires display_name' do
        valid_variant.display_name = nil
        expect(valid_variant).not_to be_valid
        expect(valid_variant.errors[:display_name]).to include("can't be blank")
      end

      # Verifica que el nombre para mostrar sea único por tienda
      # Esto evita confusiones al mostrar variantes en la misma tienda
      it 'must be unique per shop' do
        valid_variant.save!
        duplicate_variant = valid_variant.dup
        expect(duplicate_variant).not_to be_valid
        expect(duplicate_variant.errors[:display_name]).to include('has already been taken for this shop')
      end

      # Verifica que se permita el mismo nombre para mostrar en diferentes tiendas
      # Esto es útil cuando diferentes tiendas tienen productos similares
      it 'allows same display_name in different shops' do
        valid_variant.save!
        other_shop = create(:shop)
        other_variant = described_class.new(
          shop: other_shop,
          shopify_product_id: 'gid://shopify/Product/987654321',
          shopify_variant_id: 'gid://shopify/ProductVariant/123456789',
          variant_title: "Azul / S",
          display_name: valid_variant.display_name,
          is_tracked: true
        )
        expect(other_variant).to be_valid
      end
    end
  end

  # Pruebas de las asociaciones del modelo
  describe 'associations' do
    # Verifica la asociación con Shop
    it 'belongs to a shop' do
      expect(described_class.reflect_on_association(:shop).macro).to eq :belongs_to
    end

    # Verifica la asociación con InventoryLevels
    it 'has many inventory_levels' do
      expect(described_class.reflect_on_association(:inventory_levels).macro).to eq :has_many
    end

    # Verifica que al eliminar una variante se eliminen todos sus niveles de inventario
    # Esto asegura que no queden registros huérfanos en la base de datos
    it 'destroys all associated inventory_levels when variant is destroyed' do
      variant = create(:variant, shop: shop)
      # Creamos dos locations distintas
      location1 = create(:location, shop: shop)
      location2 = create(:location, shop: shop)
      # Creamos dos inventory_levels para el mismo variant pero diferentes locations
      create(:inventory_level, variant: variant, location: location1)
      create(:inventory_level, variant: variant, location: location2)

      expect { variant.destroy }.to change { InventoryLevel.count }.by(-2)
    end
  end

  # Pruebas de los scopes (consultas predefinidas) del modelo
  describe 'scopes' do
    # Configuración de variantes para probar el scope tracked
    let!(:tracked_variant) { create(:variant, is_tracked: true, shop: shop) }
    let!(:untracked_variant) { create(:variant, is_tracked: false, shop: shop) }

    # Pruebas del scope tracked
    describe '.tracked' do
      # Verifica que el scope tracked solo devuelva variantes con is_tracked = true
      it 'returns only tracked variants' do
        expect(described_class.tracked).to include(tracked_variant)
        expect(described_class.tracked).not_to include(untracked_variant)
      end
    end
  end
end 