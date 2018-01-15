class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.string :cat1
      t.string :cat2

      t.timestamps
    end
  end
end
