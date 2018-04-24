class ChangeColumnsToOrders < ActiveRecord::Migration[5.1]
  def change
    rename_column :orders, :pay, :pay_method
    rename_column :orders, :ship, :ship_method  
  end
end
