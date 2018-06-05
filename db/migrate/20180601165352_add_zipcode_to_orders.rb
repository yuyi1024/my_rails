class AddZipcodeToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :receiver_zipcode, :string, after: :receiver_address
  	rename_column :orders, :delivery_no, :shipment_no
  end
end
