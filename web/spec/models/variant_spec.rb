# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Variant, type: :model do
  let(:shop) { create(:shop) }
  let(:valid_variant) do
    described_class.new(
      shop: shop,
      shopify_product_id: 'gid://shopify/Product/123456789',
      shopify_variant_id: 'gid://shopify/ProductVariant/987654321',
      variant_title: "Test Variant",
      is_tracked: true
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_variant).to be_valid
    end

    it 'requires shopify_product_id' do
      valid_variant.shopify_product_id = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:shopify_product_id]).to include("can't be blank")
    end

    it 'requires shopify_variant_id' do
      valid_variant.shopify_variant_id = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:shopify_variant_id]).to include("can't be blank")
    end

    it 'requires unique shopify_variant_id' do
      valid_variant.save!
      duplicate_variant = valid_variant.dup
      expect(duplicate_variant).not_to be_valid
      expect(duplicate_variant.errors[:shopify_variant_id]).to include('has already been taken')
    end

    it 'requires variant_title' do
      valid_variant.variant_title = nil
      expect(valid_variant).not_to be_valid
      expect(valid_variant.errors[:variant_title]).to include("can't be blank")
    end

  end

  describe 'associations' do
    it 'belongs to a shop' do
      expect(described_class.reflect_on_association(:shop).macro).to eq :belongs_to
    end

    it 'has many inventory_levels' do
      expect(described_class.reflect_on_association(:inventory_levels).macro).to eq :has_many
    end

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

  describe 'scopes' do
    let!(:tracked_variant) { create(:variant, is_tracked: true, shop: shop) }
    let!(:untracked_variant) { create(:variant, is_tracked: false, shop: shop) }

    describe '.tracked' do
      it 'returns only tracked variants' do
        expect(described_class.tracked).to include(tracked_variant)
        expect(described_class.tracked).not_to include(untracked_variant)
      end
    end
  end
end 