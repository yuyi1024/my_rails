class AddProcessIdToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :process_id, :string
  end
end
