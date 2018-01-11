class AddColumnsToProduct < ActiveRecord::Migration[5.1]
  def change
    remove_column :products, :catrgory
    add_column :products, :category_id, :integer
    change_column :categories, :cat1, :integer
  end
end
