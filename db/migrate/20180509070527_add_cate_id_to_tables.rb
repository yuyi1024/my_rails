class AddCateIdToTables < ActiveRecord::Migration[5.1]
  def change
    add_column :subcategories, :category_id, :integer, after: :name
    add_column :products, :subcategory_id, :integer, after: :category_id
  end
end
