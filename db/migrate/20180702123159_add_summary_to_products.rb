class AddSummaryToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :summary, :text, after: :description
  end
end
