# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    association :shop
    sequence(:shopify_product_id) { |n| n }
    sequence(:shopify_variant_id) { |n| n + 1000 }
    sequence(:title) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    current_stock { 10 }
    minimum_quantity { 5 }
    status { 'active' }
    is_tracked { true }
    health_percent { 80.0 }
    sold_last_2_weeks { 5 }
    sold_last_4_weeks { 15 }
    sold_last_8_weeks { 30 }
  end
end 