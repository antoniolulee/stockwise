# frozen_string_literal: true

require 'rails_helper'

# Suite de pruebas para el modelo InventoryLevel
# Este modelo representa el nivel de inventario de una variante en una ubicación específica
RSpec.describe InventoryLevel, type: :model do
  # Configuración de datos de prueba comunes
  let(:shop) { create(:shop) }
  let(:location) { create(:location, shop: shop) }
  let(:variant) { create(:variant, shop: shop) }
  
  # Instancia válida de InventoryLevel para usar en las pruebas
  let(:valid_inventory_level) do
    described_class.new(
      location: location,
      variant: variant,
      quantity: 10,
      minimum_quantity: 10,
      health_percentage: 0.0,
      shopify_inventory_item_id: variant.shopify_variant_id
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_inventory_level).to be_valid
    end

    # Pruebas de las asociaciones del modelo
    describe 'associations' do
      # Verifica que se requiera una ubicación
      it 'requires location' do
        valid_inventory_level.location = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:location]).to include('must exist')
      end

      # Verifica que se requiera una variante
      it 'requires variant' do
        valid_inventory_level.variant = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:variant]).to include('must exist')
      end

      # Verifica que la ubicación y la variante pertenezcan a la misma tienda
      it 'requires location and variant to belong to the same shop' do
        other_shop = create(:shop)
        other_location = create(:location, shop: other_shop)
        valid_inventory_level.location = other_location
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:location]).to include('must belong to the same shop as the variant')
      end
    end

    # Pruebas de validación de la cantidad
    describe 'quantity' do
      # Verifica que se requiera una cantidad
      it 'requires quantity' do
        valid_inventory_level.quantity = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:quantity]).to include("can't be blank")
      end

      # Verifica que la cantidad debe ser un número entero
      it 'must be an integer' do
        valid_inventory_level.quantity = 10.5
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:quantity]).to include('must be an integer')
      end

      # Verifica que se permitan cantidades negativas
      it 'allows negative quantity' do
        valid_inventory_level.quantity = -5
        expect(valid_inventory_level).to be_valid
      end
    end

    # Pruebas de validación de la cantidad mínima
    describe 'minimum_quantity' do
      # Verifica que se requiera una cantidad mínima
      it 'requires minimum_quantity' do
        valid_inventory_level.minimum_quantity = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include("can't be blank")
      end

      # Verifica que la cantidad mínima debe ser un número entero
      it 'must be an integer' do
        valid_inventory_level.minimum_quantity = 10.5
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include('must be an integer')
      end

      # Verifica que la cantidad mínima no puede ser negativa
      it 'must be greater than or equal to zero' do
        valid_inventory_level.minimum_quantity = -1
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include('must be greater than or equal to 0')
      end

      # Pruebas del valor por defecto
      describe 'default value' do
        it 'sets minimum_quantity to 0 by default when creating a new record' do
          new_inventory_level = described_class.new(
            location: location,
            variant: variant,
            quantity: 10,
            shopify_inventory_item_id: variant.shopify_variant_id
          )
          expect(new_inventory_level.minimum_quantity).to eq(0)
        end

        it 'persists minimum_quantity as 0 when saving without specifying it' do
          new_inventory_level = described_class.create!(
            location: location,
            variant: variant,
            quantity: 10,
            shopify_inventory_item_id: variant.shopify_variant_id
          )
          expect(new_inventory_level.reload.minimum_quantity).to eq(0)
        end

        it 'allows overriding the default value when explicitly set' do
          new_inventory_level = described_class.create!(
            location: location,
            variant: variant,
            quantity: 10,
            minimum_quantity: 5,
            shopify_inventory_item_id: variant.shopify_variant_id
          )
          expect(new_inventory_level.reload.minimum_quantity).to eq(5)
        end
      end
    end

    # Pruebas de validación del porcentaje de salud
    describe 'health_percentage' do
      # Verifica que se requiera un porcentaje de salud
      it 'requires health_percentage' do
        valid_inventory_level.health_percentage = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:health_percentage]).to include("can't be blank")
      end

      # Verifica que el porcentaje de salud debe ser un número decimal
      it 'must be a decimal' do
        valid_inventory_level.health_percentage = 'not a number'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:health_percentage]).to include('is not a number')
      end

      # Verifica que el porcentaje de salud puede ser negativo cuando la cantidad está por debajo del mínimo
      it 'can be negative' do
        valid_inventory_level.quantity = 5
        valid_inventory_level.minimum_quantity = 10
        valid_inventory_level.valid?
        expect(valid_inventory_level.health_percentage).to eq(-50.0)
      end

      # Verifica que el porcentaje de salud puede ser mayor a 100 cuando la cantidad está por encima del doble del mínimo
      it 'can be greater than 100' do
        valid_inventory_level.quantity = 30
        valid_inventory_level.minimum_quantity = 10
        valid_inventory_level.valid?
        expect(valid_inventory_level.health_percentage).to eq(200.0)
      end
    end

    # Pruebas de validación del ID de inventario de Shopify
    describe 'shopify_inventory_item_id' do
      # Verifica que se requiera un ID de inventario de Shopify
      it 'requires shopify_inventory_item_id' do
        valid_inventory_level.shopify_inventory_item_id = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id]).to include("can't be blank")
      end

      # Verifica que el ID de inventario debe seguir el formato GID de Shopify
      it 'must follow Shopify GID format' do
        valid_inventory_level.shopify_inventory_item_id = 'invalid-id'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id])
          .to include('must be a valid Shopify GID')
      end

      # Verifica que el ID de inventario debe ser único por ubicación y variante
      it 'requires unique shopify_inventory_item_id per location and variant' do
        valid_inventory_level.save!
        duplicate_inventory_level = valid_inventory_level.dup
        duplicate_inventory_level.location = valid_inventory_level.location
        duplicate_inventory_level.variant = valid_inventory_level.variant
        expect(duplicate_inventory_level).not_to be_valid
        expect(duplicate_inventory_level.errors[:shopify_inventory_item_id])
          .to include('has already been taken for this location and variant')
      end

      # Verifica que el ID de inventario debe coincidir con el ID de la variante
      it 'requires shopify_inventory_item_id to match variant shopify_variant_id' do
        valid_inventory_level.shopify_inventory_item_id = 'gid://shopify/InventoryItem/otherid'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id])
          .to include('must match the variant shopify_variant_id')
      end
    end
  end

  # Pruebas de las asociaciones del modelo
  describe 'associations' do
    # Verifica la asociación con Location
    it 'belongs to a location' do
      expect(described_class.reflect_on_association(:location).macro).to eq :belongs_to
    end

    # Verifica la asociación con Variant
    it 'belongs to a variant' do
      expect(described_class.reflect_on_association(:variant).macro).to eq :belongs_to
    end
  end

  # Pruebas del cálculo del porcentaje de salud
  describe 'health percentage calculation' do
    let(:shop) { create(:shop) }
    let(:location) { create(:location, shop: shop) }
    let(:variant) { create(:variant, shop: shop) }
    let(:inventory_level) do
      create(:inventory_level,
             location: location,
             variant: variant,
             quantity: 10,
             minimum_quantity: 10,
             shopify_inventory_item_id: variant.shopify_variant_id)
    end

    # Prueba los diferentes escenarios de cálculo del porcentaje de salud
    it 'calculates health percentage based on current quantity and minimum quantity' do
      # Cuando la cantidad es el doble del mínimo, la salud es 100%
      inventory_level.update(quantity: 20)
      expect(inventory_level.health_percentage).to eq(100.0)

      # Cuando la cantidad es igual al mínimo, la salud es 0%
      inventory_level.update(quantity: 10)
      expect(inventory_level.health_percentage).to eq(0.0)

      # Cuando la cantidad está por debajo del mínimo, la salud es negativa
      inventory_level.update(quantity: 5)
      expect(inventory_level.health_percentage).to eq(-50.0)

      # Cuando la cantidad está por encima del doble del mínimo, la salud es mayor a 100%
      inventory_level.update(quantity: 30)
      expect(inventory_level.health_percentage).to eq(200.0)
    end

    # Verifica que el porcentaje de salud se actualiza cuando cambia la cantidad
    it 'updates health_percentage when quantity changes' do
      inventory_level.update(quantity: 20)
      expect(inventory_level.health_percentage).to eq(100.0)

      inventory_level.update(quantity: 5)
      expect(inventory_level.health_percentage).to eq(-50.0)
    end

    # Verifica que el porcentaje de salud se actualiza cuando cambia la cantidad mínima
    it 'updates health_percentage when minimum_quantity changes' do
      inventory_level.update(quantity: 20, minimum_quantity: 10)
      expect(inventory_level.health_percentage).to eq(100.0)

      inventory_level.update(minimum_quantity: 5)
      expect(inventory_level.health_percentage).to eq(300.0)
    end

    # Verifica que el porcentaje de salud es 0.0 cuando la cantidad mínima es 0
    it 'returns 0.0 for health_percentage when minimum_quantity is 0' do
      inventory_level.update(quantity: 10, minimum_quantity: 0)
      expect(inventory_level.health_percentage).to eq(0.0)
    end
  end
end 