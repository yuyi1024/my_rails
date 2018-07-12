class AddOrderIdToRemittanceInfos < ActiveRecord::Migration[5.1]
  def change
    add_column :remittance_infos, :order_id, :integer
  end
end
