class CreateImages < ActiveRecord::Migration[5.1]
  def change
    create_table :images do |t|
      t.string :filename
      t.integer :size
      t.string :content_type

      t.timestamps
    end
  end
end
