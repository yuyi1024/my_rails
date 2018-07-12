class CreateRemittanceInfos < ActiveRecord::Migration[5.1]
  def change
    create_table :remittance_infos do |t|
      t.string :transfer_type
      t.integer :price
      t.datetime :date
      t.string :remit_data
      t.string :refund_bank
      t.string :refund_account
      t.string :checked, :default => 'false'

      t.timestamps
    end
  end
end
