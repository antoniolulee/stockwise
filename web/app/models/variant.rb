# frozen_string_literal: true

class Variant < ApplicationRecord
  belongs_to :shop
  has_many :inventory_levels, dependent: :destroy

  validates :shopify_product_id, presence: true
  validates :shopify_variant_id, presence: true, uniqueness: true
  validates :variant_title, presence: true
  validates :display_name, presence: true,
                         uniqueness: { scope: :shop_id, message: 'has already been taken for this shop' }

  scope :tracked, -> { where(is_tracked: true) }
end 