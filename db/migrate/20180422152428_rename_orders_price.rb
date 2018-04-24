class RenameOrdersPrice < ActiveRecord::Migration[5.1]
  def change
  	rename_column :orders, :total_price, :price
  end
end
