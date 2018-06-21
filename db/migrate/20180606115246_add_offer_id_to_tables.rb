class AddOfferIdToTables < ActiveRecord::Migration[5.1]
  def change
  	add_column :products, :offer_id, :integer
  end
end
