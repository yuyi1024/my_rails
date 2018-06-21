class AddCateIdToTables < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :subcategory_id, :integer, after: :category_id
  end
end
