# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:shop) { create(:shop) }
  let(:valid_product) do
    described_class.new(
      shop: shop,
      shopify_product_id: 123456789,
      shopify_variant_id: 987654321,
      title: "Test Product",
      sku: "TEST-123",
      current_stock: 10,
      status: "active",
      is_tracked: true,
      minimum_quantity: 5,
      health_percent: 100.0,
      sold_last_2_weeks: 5,
      sold_last_4_weeks: 15,
      sold_last_8_weeks: 30
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_product).to be_valid
    end

    it 'requires shopify_product_id' do
      valid_product.shopify_product_id = nil
      expect(valid_product).not_to be_valid
      expect(valid_product.errors[:shopify_product_id]).to include("can't be blank")
    end

    it 'requires unique shopify_product_id and shopify_variant_id combination' do
      valid_product.save!
      duplicate_product = valid_product.dup
      expect(duplicate_product).not_to be_valid
      expect(duplicate_product.errors[:shopify_variant_id]).to include('has already been taken for this product')
    end

    it 'requires title' do
      valid_product.title = nil
      expect(valid_product).not_to be_valid
      expect(valid_product.errors[:title]).to include("can't be blank")
    end

    it 'requires minimum_quantity to be greater than or equal to 0' do
      valid_product.minimum_quantity = -1
      expect(valid_product).not_to be_valid
      expect(valid_product.errors[:minimum_quantity]).to include('must be greater than or equal to 0')
    end

    it 'allows health_percent to be any number' do
      valid_product.health_percent = -50.0
      expect(valid_product).to be_valid

      valid_product.health_percent = 200.0
      expect(valid_product).to be_valid
    end

    it 'requires status to be either active or inactive' do
      valid_product.status = 'invalid'
      expect(valid_product).not_to be_valid
      expect(valid_product.errors[:status]).to include('is not included in the list')
    end
  end

  describe 'scopes' do
    let!(:active_product) { create(:product, status: 'active', shop: shop) }
    let!(:inactive_product) { create(:product, status: 'inactive', shop: shop) }

    describe '.active' do
      it 'returns only active products' do
        expect(described_class.active).to include(active_product)
        expect(described_class.active).not_to include(inactive_product)
      end
    end

    describe '.inactive' do
      it 'returns only inactive products' do
        expect(described_class.inactive).to include(inactive_product)
        expect(described_class.inactive).not_to include(active_product)
      end
    end

    describe '.tracked' do
      let!(:tracked_product) { create(:product, is_tracked: true, shop: shop) }
      let!(:untracked_product) { create(:product, is_tracked: false, shop: shop) }

      it 'returns only tracked products' do
        expect(described_class.tracked).to include(tracked_product)
        expect(described_class.tracked).not_to include(untracked_product)
      end
    end

    describe '.low_stock' do
      let!(:low_stock_product) { create(:product, current_stock: 5, minimum_quantity: 10, is_tracked: true, shop: shop) }
      let!(:healthy_stock_product) { create(:product, current_stock: 15, minimum_quantity: 10, is_tracked: true, shop: shop) }
      let!(:untracked_low_stock) { create(:product, current_stock: 5, minimum_quantity: 10, is_tracked: false, shop: shop) }

      it 'returns only tracked products with stock below minimum' do
        expect(described_class.low_stock).to include(low_stock_product)
        expect(described_class.low_stock).not_to include(healthy_stock_product)
        expect(described_class.low_stock).not_to include(untracked_low_stock)
      end
    end
  end

  describe '#update_stock' do
    before { valid_product.save! }

    it 'updates stock correctly' do
      valid_product.update_stock(5)
      expect(valid_product.reload.current_stock).to eq(15)
    end

    it 'allows negative stock' do
      valid_product.update_stock(-20)
      expect(valid_product.reload.current_stock).to eq(-10)
    end
  end

  describe '#calculate_health_percent' do
    it 'calculates health percent based on current stock and minimum quantity' do
      product = create(:product, current_stock: 8, minimum_quantity: 10)
      # ((8 - 10) / 10) * 100 = -20%
      expect(product.health_percent).to eq(-20.0)
    end

    it 'returns 0 when current stock equals minimum quantity' do
      product = create(:product, current_stock: 10, minimum_quantity: 10)
      # ((10 - 10) / 10) * 100 = 0%
      expect(product.health_percent).to eq(0.0)
    end

    it 'returns 100 when current stock is double minimum quantity' do
      product = create(:product, current_stock: 20, minimum_quantity: 10)
      # ((20 - 10) / 10) * 100 = 100%
      expect(product.health_percent).to eq(100.0)
    end

    it 'returns 50 when current stock is 1.5 times minimum quantity' do
      product = create(:product, current_stock: 15, minimum_quantity: 10)
      # ((15 - 10) / 10) * 100 = 50%
      expect(product.health_percent).to eq(50.0)
    end

    it 'allows health percent over 100' do
      product = create(:product, current_stock: 30, minimum_quantity: 10)
      # ((30 - 10) / 10) * 100 = 200%
      expect(product.health_percent).to eq(200.0)
    end

    it 'allows negative health percent' do
      product = create(:product, current_stock: 5, minimum_quantity: 10)
      # ((5 - 10) / 10) * 100 = -50%
      expect(product.health_percent).to eq(-50.0)
    end
  end
end 