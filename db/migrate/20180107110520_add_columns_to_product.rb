class AddColumnsToProduct < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :category_id, :integer
    change_column :categories, :cat1, :integer
  end
end
