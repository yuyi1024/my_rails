class CreateBanks < ActiveRecord::Migration[5.1]
  def change
    create_table :banks do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end
end
