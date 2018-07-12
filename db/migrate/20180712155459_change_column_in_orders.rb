class ChangeColumnInOrders < ActiveRecord::Migration[5.1]
  def change
    rename_column :orders, :delivered, :shipped
    remove_column :orders, :remit_data
  end
end
