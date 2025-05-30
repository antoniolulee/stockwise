# frozen_string_literal: true

class AddDefaultValueToMinimumQuantity < ActiveRecord::Migration[7.1]
  def change
    change_column_default :inventory_levels, :minimum_quantity, from: nil, to: 0
  end
end
