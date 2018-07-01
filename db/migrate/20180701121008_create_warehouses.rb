class CreateWarehouses < ActiveRecord::Migration[5.1]
  def change
    create_table :warehouses do |t|
      t.integer :room
      t.string :shelf
      t.integer :row
      t.integer :column

      t.timestamps
    end
  end
end
