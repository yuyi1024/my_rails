class SetDefaultToTables < ActiveRecord::Migration[5.1]
  def change
  	change_column :products, :sold, :integer, :default => 0
  	change_column :products, :click_count, :integer, :default => 0
  	change_column :orders, :paid, :string, :default => 'false'
  	change_column :orders, :delivered, :string, :default => 'false'
  end
end
