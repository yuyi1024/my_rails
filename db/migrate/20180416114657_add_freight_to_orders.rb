class AddFreightToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :freight, :integer
  end
end
