# frozen_string_literal: true

class Location < ApplicationRecord
  belongs_to :shop
  has_many :inventory_levels, dependent: :destroy

  validates :shopify_location_id, presence: true
  validates :name, presence: true
  validates :shopify_location_id, uniqueness: { scope: :shop_id, message: 'has already been taken for this shop' }

  scope :active, -> { where(is_active: true) }
end 