# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :locations do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_location_id, null: false
      t.string :name, null: false
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :locations, [:shop_id, :shopify_location_id], unique: true
  end
end 