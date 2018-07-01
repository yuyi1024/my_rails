class AddWarehouseToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :quantity_alert, :integer, after: :quantity
    add_column :products, :warehouse, :string, after: :quantity_alert
  end
end
