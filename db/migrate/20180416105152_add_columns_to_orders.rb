class AddColumnsToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :total_price, :integer
  	add_column :orders, :true_name, :string
  	add_column :orders, :address, :string
  	add_column :orders, :phone, :string

		add_column :users, :true_name, :string
  	add_column :users, :address, :string
  	add_column :users, :phone, :string  	
  end
end
