class AddOfferIdToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :offer_id, :integer, after: :process_id 
  	add_column :order_items, :offer_id, :integer, after: :quantity 
  end
end
