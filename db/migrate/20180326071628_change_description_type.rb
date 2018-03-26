class ChangeDescriptionType < ActiveRecord::Migration[5.1]
  def change
  	change_column :products, :description, :text
  end
end
