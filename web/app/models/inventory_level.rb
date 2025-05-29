# frozen_string_literal: true

class InventoryLevel < ApplicationRecord
  belongs_to :location
  belongs_to :variant

  # === Validations ===
  # Presence
  validates :quantity, :minimum_quantity, :health_percentage, :shopify_inventory_item_id, presence: true

  # Type
  validates :quantity, :minimum_quantity, numericality: { only_integer: true }
  validates :health_percentage, numericality: true
  validates :shopify_inventory_item_id, format: {
    with: %r{\Agid://shopify/InventoryItem/\d+\z},
    message: 'must be a valid Shopify GID'
  }

  # Range
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }

  # Uniqueness
  validates :shopify_inventory_item_id, uniqueness: {
    scope: %i[location_id variant_id],
    message: 'has already been taken for this location and variant'
  }

  # Custom validations
  validate :location_and_variant_belong_to_same_shop
  validate :shopify_inventory_item_id_matches_variant

  # === Callbacks ===
  after_validation :calculate_health_percentage, if: :can_calculate_health_percentage?

  private

  def can_calculate_health_percentage?
    quantity.present? && minimum_quantity.present?
  end

  def calculate_health_percentage
    self.health_percentage = ((quantity - minimum_quantity).to_f / minimum_quantity) * 100
  end

  def location_and_variant_belong_to_same_shop
    return if location.blank? || variant.blank?
    return if location.shop_id == variant.shop_id

    errors.add(:location, 'must belong to the same shop as the variant')
  end

  def shopify_inventory_item_id_matches_variant
    return if shopify_inventory_item_id.blank? || variant.blank?
    return if shopify_inventory_item_id == variant.shopify_variant_id

    errors.add(:shopify_inventory_item_id, 'must match the variant shopify_variant_id')
  end
end 