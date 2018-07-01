class ChangeRoomToWarthouses < ActiveRecord::Migration[5.1]
  def change
    change_column :warehouses, :room, :integer
  end
end
