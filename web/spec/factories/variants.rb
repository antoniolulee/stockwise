# frozen_string_literal: true

FactoryBot.define do
  factory :variant do
    association :shop
    sequence(:shopify_product_id) { |n| "gid://shopify/Product/#{n}" }
    sequence(:shopify_variant_id) { |n| "gid://shopify/InventoryItem/#{n}" }
    variant_title { 'Azul / S' }
    sequence(:display_name) { |n| "Camiseta Surf #{n} - Azul / S" }
    is_tracked { true }
  end
end 