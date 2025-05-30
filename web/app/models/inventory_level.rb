# frozen_string_literal: true

# InventoryLevel representa el nivel de inventario de una variante en una ubicación específica.
# Mantiene un registro de la cantidad actual, la cantidad mínima requerida y calcula
# el porcentaje de salud del inventario.
class InventoryLevel < ApplicationRecord
  # === Associations ===
  belongs_to :location  # La ubicación donde se almacena el inventario
  belongs_to :variant   # La variante del producto a la que pertenece este nivel de inventario

  # === Attributes ===
  attribute :health_percentage, :decimal, default: 0.0

  # === Validations ===
  # Validaciones de presencia
  validates :quantity, :minimum_quantity, :health_percentage, :shopify_inventory_item_id, presence: true

  # Validaciones de tipo
  validates :quantity, :minimum_quantity, numericality: { only_integer: true }  # Solo permite números enteros
  validates :health_percentage, numericality: true  # Permite números decimales
  validates :shopify_inventory_item_id, format: {
    with: %r{\Agid://shopify/InventoryItem/\d+\z},
    message: 'must be a valid Shopify GID'
  }

  # Validaciones de rango
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }  # No permite cantidades negativas

  # Validaciones de unicidad
  validates :shopify_inventory_item_id, uniqueness: {
    scope: %i[location_id variant_id],
    message: 'has already been taken for this location and variant'
  }

  # Validaciones personalizadas
  validate :location_and_variant_belong_to_same_shop  # Asegura que la ubicación y la variante pertenezcan a la misma tienda
  validate :shopify_inventory_item_id_matches_variant  # Verifica que el ID de inventario coincida con la variante

  # === Callbacks ===
  # Calcula el porcentaje de salud del inventario después de la validación
  # si tanto la cantidad como la cantidad mínima están presentes
  after_validation :calculate_health_percentage, if: :can_calculate_health_percentage?

  private

  # Verifica si es posible calcular el porcentaje de salud del inventario
  # @return [Boolean] true si tanto quantity como minimum_quantity están presentes
  def can_calculate_health_percentage?
    quantity.present? && minimum_quantity.present?
  end

  # Calcula el porcentaje de salud del inventario basado en la cantidad actual y mínima
  # La fórmula es: ((cantidad_actual - cantidad_mínima) / cantidad_mínima) * 100
  # Si la cantidad mínima es 0, el porcentaje de salud se establece en 0.0
  def calculate_health_percentage
    if minimum_quantity > 0
      self.health_percentage = ((quantity - minimum_quantity).to_f / minimum_quantity * 100).round(2)
    else
      self.health_percentage = 0.0
    end
  end

  # Valida que la ubicación y la variante pertenezcan a la misma tienda
  # @return [void]
  def location_and_variant_belong_to_same_shop
    return if location.blank? || variant.blank?
    return if location.shop_id == variant.shop_id

    errors.add(:location, 'must belong to the same shop as the variant')
  end

  # Valida que el ID de inventario de Shopify coincida con el ID de la variante
  # @return [void]
  def shopify_inventory_item_id_matches_variant
    return if shopify_inventory_item_id.blank? || variant.blank?
    return if shopify_inventory_item_id == variant.shopify_variant_id

    errors.add(:shopify_inventory_item_id, 'must match the variant shopify_variant_id')
  end
end 