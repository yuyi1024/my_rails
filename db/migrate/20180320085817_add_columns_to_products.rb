class AddColumnsToProducts < ActiveRecord::Migration[5.1]
  def change
  	add_column :products, :quantity, :integer
  	add_column :products, :sold, :integer
  	add_column :products, :click_count, :integer
  	add_column :products, :picture_id, :integer
  end
end
