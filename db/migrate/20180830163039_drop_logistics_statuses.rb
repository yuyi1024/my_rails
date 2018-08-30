class DropLogisticsStatuses < ActiveRecord::Migration[5.1]
  def change
	  drop_table :logistics_statuses
  end
end
