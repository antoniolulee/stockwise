FactoryBot.define do
  factory :location do
    association :shop
    sequence(:shopify_location_id) { |n| "gid://shopify/Location/#{n}" }
    sequence(:name) { |n| "Location #{n}" }
    is_active { true }
  end
end 