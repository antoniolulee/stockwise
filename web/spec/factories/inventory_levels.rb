# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_level do
    association :location
    association :variant
    quantity { 10 }
    minimum_quantity { 10 }
    health_percentage { 0.0 }
    shopify_inventory_item_id { variant.shopify_variant_id }
  end
end 