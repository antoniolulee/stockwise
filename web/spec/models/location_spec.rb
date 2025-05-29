# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:shop) { create(:shop) }
  let(:valid_location) do
    described_class.new(
      shop: shop,
      shopify_location_id: 'gid://shopify/Location/123456789',
      name: 'Main Warehouse',
      is_active: true
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_location).to be_valid
    end

    it 'requires shopify_location_id' do
      valid_location.shopify_location_id = nil
      expect(valid_location).not_to be_valid
      expect(valid_location.errors[:shopify_location_id]).to include("can't be blank")
    end

    it 'requires unique shopify_location_id per shop' do
      valid_location.save!
      duplicate_location = valid_location.dup
      expect(duplicate_location).not_to be_valid
      expect(duplicate_location.errors[:shopify_location_id]).to include('has already been taken for this shop')
    end

    it 'requires name' do
      valid_location.name = nil
      expect(valid_location).not_to be_valid
      expect(valid_location.errors[:name]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to a shop' do
      expect(described_class.reflect_on_association(:shop).macro).to eq :belongs_to
    end

    it 'has many inventory_levels' do
      expect(described_class.reflect_on_association(:inventory_levels).macro).to eq :has_many
    end
  end

  describe 'scopes' do
    let!(:active_location) { create(:location, is_active: true, shop: shop) }
    let!(:inactive_location) { create(:location, is_active: false, shop: shop) }

    describe '.active' do
      it 'returns only active locations' do
        expect(described_class.active).to include(active_location)
        expect(described_class.active).not_to include(inactive_location)
      end
    end
  end
end 