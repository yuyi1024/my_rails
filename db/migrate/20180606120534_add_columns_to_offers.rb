class AddColumnsToOffers < ActiveRecord::Migration[5.1]
  def change
  	add_column :offers, :range_subcats, :string, after: :range_quantity
  	add_column :offers, :range_products, :string, after: :range_subcats
  end
end
