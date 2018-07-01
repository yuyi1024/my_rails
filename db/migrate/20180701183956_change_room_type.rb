class ChangeRoomType < ActiveRecord::Migration[5.1]
  def change
  	change_column :warehouses, :room, :string
  end
end
