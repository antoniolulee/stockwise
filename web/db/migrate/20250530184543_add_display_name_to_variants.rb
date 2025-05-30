class AddDisplayNameToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :display_name, :string
    add_index :variants, [:display_name, :shop_id], unique: true, name: 'index_variants_on_display_name_and_shop_id'
  end
end
