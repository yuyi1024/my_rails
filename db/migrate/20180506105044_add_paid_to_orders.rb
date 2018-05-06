class AddPaidToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :paid, :string
  end
end
