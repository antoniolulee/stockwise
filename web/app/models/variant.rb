# frozen_string_literal: true

class Variant < ApplicationRecord
  belongs_to :shop
  has_many :inventory_levels, dependent: :destroy

  validates :shopify_product_id, presence: true
  validates :shopify_variant_id, presence: true, uniqueness: true
  validates :variant_title, presence: true
  validates :minimum_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :tracked, -> { where(is_tracked: true) }
end 