# frozen_string_literal: true

class AddMinimumQuantityToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :minimum_quantity, :integer, null: false, default: 0
    add_check_constraint :variants, "minimum_quantity >= 0", name: "check_minimum_quantity_positive"
  end
end
