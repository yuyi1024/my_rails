class AddCacheToProduct < ActiveRecord::Migration[5.1]
  def change
  	add_column :products, :cache, :string
  end
end
