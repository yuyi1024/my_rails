class ChangeWarehouseToProducts < ActiveRecord::Migration[5.1]
  def change
  	rename_column :products, :warehouse, :warehouse_id
  	change_column :products, :warehouse_id, :integer
  end
end
