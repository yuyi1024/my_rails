class AddTimeToRemitData < ActiveRecord::Migration[5.1]
  def change
  	remove_column :remittance_infos, :date
  	add_column :remittance_infos, :date, :date, after: :price
  	add_column :remittance_infos, :time, :time, after: :date
  end
end
