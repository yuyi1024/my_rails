class AddNoteToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :note, :text
  end
end
