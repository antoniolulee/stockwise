# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shop, type: :model do
  let(:valid_shop) do
    described_class.new(
      shopify_domain: 'test-shop.myshopify.com',
      shopify_token: 'test-token',
      access_scopes: 'read_products,write_products'
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_shop).to be_valid
    end

    it 'requires shopify_domain' do
      valid_shop.shopify_domain = nil
      expect(valid_shop).not_to be_valid
      expect(valid_shop.errors[:shopify_domain]).to include("can't be blank")
    end

    it 'requires shopify_token' do
      valid_shop.shopify_token = nil
      expect(valid_shop).not_to be_valid
      expect(valid_shop.errors[:shopify_token]).to include("can't be blank")
    end

    it 'requires unique shopify_domain' do
      valid_shop.save!
      duplicate_shop = valid_shop.dup
      expect(duplicate_shop).not_to be_valid
      expect(duplicate_shop.errors[:shopify_domain]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'has many variants' do
      expect(described_class.reflect_on_association(:variants).macro).to eq :has_many
    end
  end

  describe '#api_version' do
    it 'returns the configured API version' do
      expect(valid_shop.api_version).to eq(ShopifyApp.configuration.api_version)
    end
  end
end 