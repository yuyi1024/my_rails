class ChangeOrdersColumn < ActiveRecord::Migration[5.1]
  def change
  	change_column :orders, :address, :string, after: :ship_method
  	change_column :orders, :price, :integer, after: :status
  	change_column :orders, :freight, :integer, after: :price
  	change_column :orders, :created_at, :datetime, after: :note
  	change_column :orders, :updated_at, :datetime, after: :created_at

  end
end
