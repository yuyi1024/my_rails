class AddStatusToLogisticsStatus < ActiveRecord::Migration[5.1]
  def change
  	add_column :logistics_statuses, :status, :string, after: :message
  end
end
