# frozen_string_literal: true

FactoryBot.define do
  factory :shop do
    sequence(:shopify_domain) { |n| "shop-#{n}.myshopify.com" }
    sequence(:shopify_token) { |n| "token-#{n}" }
    access_scopes { "read_products,write_products" }
  end
end 