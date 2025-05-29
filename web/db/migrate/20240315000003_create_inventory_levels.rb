# frozen_string_literal: true

class CreateInventoryLevels < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_levels do |t|
      t.references :location, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :minimum_quantity, null: false
      t.decimal :health_percentage, precision: 10, scale: 2, null: false
      t.string :shopify_inventory_item_id, null: false

      t.timestamps
    end

    add_index :inventory_levels, [:location_id, :variant_id, :shopify_inventory_item_id], 
              unique: true, 
              name: 'index_inventory_levels_on_location_variant_and_shopify_item'
  end
end 