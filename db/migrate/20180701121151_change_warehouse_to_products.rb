class ChangeWarehouseToProducts < ActiveRecord::Migration[5.1]
  def change
  	rename_column :products, :warehouse, :warehouse_id
  	remove_column :products, :warehouse_id
  	add_column :products, :warehouse_id, :integer, after: :quantity_alert
  	# change_column :products, :warehouse_id, :integer
  end
end
