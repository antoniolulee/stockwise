class RemoveMinimumQuantityFromVariants < ActiveRecord::Migration[7.1]
  def change
    remove_column :variants, :minimum_quantity, :integer
  end
end
