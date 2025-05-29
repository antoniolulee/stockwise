# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryLevel, type: :model do
  let(:shop) { create(:shop) }
  let(:location) { create(:location, shop: shop) }
  let(:variant) { create(:variant, shop: shop, minimum_quantity: 10) }
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

    describe 'associations' do
      it 'requires location' do
        valid_inventory_level.location = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:location]).to include('must exist')
      end

      it 'requires variant' do
        valid_inventory_level.variant = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:variant]).to include('must exist')
      end

      it 'requires location and variant to belong to the same shop' do
        other_shop = create(:shop)
        other_location = create(:location, shop: other_shop)
        valid_inventory_level.location = other_location
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:location]).to include('must belong to the same shop as the variant')
      end
    end

    describe 'quantity' do
      it 'requires quantity' do
        valid_inventory_level.quantity = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:quantity]).to include("can't be blank")
      end

      it 'must be an integer' do
        valid_inventory_level.quantity = 10.5
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:quantity]).to include('must be an integer')
      end

      it 'allows negative quantity' do
        valid_inventory_level.quantity = -5
        expect(valid_inventory_level).to be_valid
      end
    end

    describe 'minimum_quantity' do
      it 'requires minimum_quantity' do
        valid_inventory_level.minimum_quantity = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include("can't be blank")
      end

      it 'must be an integer' do
        valid_inventory_level.minimum_quantity = 10.5
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include('must be an integer')
      end

      it 'must be greater than or equal to zero' do
        valid_inventory_level.minimum_quantity = -1
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:minimum_quantity]).to include('must be greater than or equal to 0')
      end
    end

    describe 'health_percentage' do
      it 'requires health_percentage' do
        valid_inventory_level.health_percentage = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:health_percentage]).to include("can't be blank")
      end

      it 'must be a decimal' do
        valid_inventory_level.health_percentage = 'not a number'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:health_percentage]).to include('is not a number')
      end

      it 'can be negative' do
        valid_inventory_level.quantity = 5
        valid_inventory_level.minimum_quantity = 10
        valid_inventory_level.valid?
        expect(valid_inventory_level.health_percentage).to eq(-50.0)
      end

      it 'can be greater than 100' do
        valid_inventory_level.quantity = 30
        valid_inventory_level.minimum_quantity = 10
        valid_inventory_level.valid?
        expect(valid_inventory_level.health_percentage).to eq(200.0)
      end
    end

    describe 'shopify_inventory_item_id' do
      it 'requires shopify_inventory_item_id' do
        valid_inventory_level.shopify_inventory_item_id = nil
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id]).to include("can't be blank")
      end

      it 'must follow Shopify GID format' do
        valid_inventory_level.shopify_inventory_item_id = 'invalid-id'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id])
          .to include('must be a valid Shopify GID')
      end

      it 'requires unique shopify_inventory_item_id per location and variant' do
        valid_inventory_level.save!
        duplicate_inventory_level = valid_inventory_level.dup
        duplicate_inventory_level.location = valid_inventory_level.location
        duplicate_inventory_level.variant = valid_inventory_level.variant
        expect(duplicate_inventory_level).not_to be_valid
        expect(duplicate_inventory_level.errors[:shopify_inventory_item_id])
          .to include('has already been taken for this location and variant')
      end

      it 'requires shopify_inventory_item_id to match variant shopify_variant_id' do
        valid_inventory_level.shopify_inventory_item_id = 'gid://shopify/InventoryItem/otherid'
        expect(valid_inventory_level).not_to be_valid
        expect(valid_inventory_level.errors[:shopify_inventory_item_id])
          .to include('must match the variant shopify_variant_id')
      end
    end
  end

  describe 'associations' do
    it 'belongs to a location' do
      expect(described_class.reflect_on_association(:location).macro).to eq :belongs_to
    end

    it 'belongs to a variant' do
      expect(described_class.reflect_on_association(:variant).macro).to eq :belongs_to
    end
  end

  describe 'health percentage calculation' do
    let(:shop) { create(:shop) }
    let(:location) { create(:location, shop: shop) }
    let(:variant) { create(:variant, shop: shop, minimum_quantity: 10) }
    let(:inventory_level) do
      create(:inventory_level,
             location: location,
             variant: variant,
             shopify_inventory_item_id: variant.shopify_variant_id)
    end

    it 'calculates health percentage based on current quantity and minimum quantity' do
      # When quantity is double the minimum, health is 100%
      inventory_level.update(quantity: 20)
      expect(inventory_level.health_percentage).to eq(100.0)

      # When quantity equals minimum, health is 0%
      inventory_level.update(quantity: 10)
      expect(inventory_level.health_percentage).to eq(0.0)

      # When quantity is below minimum, health is negative
      inventory_level.update(quantity: 5)
      expect(inventory_level.health_percentage).to eq(-50.0)

      # When quantity is above double minimum, health is over 100%
      inventory_level.update(quantity: 30)
      expect(inventory_level.health_percentage).to eq(200.0)
    end

    it 'updates health_percentage when quantity changes' do
      inventory_level.update(quantity: 20)
      expect(inventory_level.health_percentage).to eq(100.0)

      inventory_level.update(quantity: 5)
      expect(inventory_level.health_percentage).to eq(-50.0)
    end

    it 'updates health_percentage when minimum_quantity changes' do
      inventory_level.update(quantity: 20, minimum_quantity: 10)
      expect(inventory_level.health_percentage).to eq(100.0)

      inventory_level.update(minimum_quantity: 5)
      expect(inventory_level.health_percentage).to eq(300.0)
    end
  end
end 