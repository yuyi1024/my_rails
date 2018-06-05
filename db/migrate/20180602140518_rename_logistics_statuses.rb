class RenameLogisticsStatuses < ActiveRecord::Migration[5.1]
  def change
  	rename_column :logistics_statuses, :type, :logistics_type
  	rename_column :logistics_statuses, :subtype, :logistics_subtype

  	add_column :orders, :remit_data, :string, after: :note
  end
end
