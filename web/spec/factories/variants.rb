FactoryBot.define do
  factory :variant do
    association :shop
    sequence(:shopify_product_id) { |n| "gid://shopify/Product/#{n}" }
    sequence(:shopify_variant_id) { |n| "gid://shopify/ProductVariant/#{n}" }
    sequence(:variant_title) { |n| "Variant #{n}" }
    is_tracked { true }
  end
end 