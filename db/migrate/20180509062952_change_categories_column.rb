class ChangeCategoriesColumn < ActiveRecord::Migration[5.1]
  def change
  	remove_column :categories, :cat1
  	remove_column :categories, :cat2
  	add_column :categories, :name, :string, after: :id 
  end
end
