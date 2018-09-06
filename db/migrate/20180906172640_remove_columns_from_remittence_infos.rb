class RemoveColumnsFromRemittenceInfos < ActiveRecord::Migration[5.1]
  def change
    remove_column :remittance_infos, :transfer_type
    remove_column :remittance_infos, :remit_data
    remove_column :remittance_infos, :checked
    change_column :remittance_infos, :refund_bank, :string, after: :id
    change_column :remittance_infos, :refund_account, :string, after: :refund_bank
    add_column :remittance_infos, :refunded, :boolean, after: :refund_account, default: false
  end
end
