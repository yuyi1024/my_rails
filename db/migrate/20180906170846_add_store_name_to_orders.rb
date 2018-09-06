class AddStoreNameToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :receiver_store_name, :string, after: :receiver_store_id
  end
end
