class CreateVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_product_id, null: false
      t.string :shopify_variant_id, null: false
      t.string :variant_title, null: false
      t.boolean :is_tracked, default: true

      t.timestamps
    end

    add_index :variants, :shopify_variant_id, unique: true
  end
end 