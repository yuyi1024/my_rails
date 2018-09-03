class CreateEcpayPaymentAtmInfos < ActiveRecord::Migration[5.1]
  def change
    create_table :ecpay_payment_atm_infos do |t|
      t.integer :order_id
      t.integer :user_id
      t.string :bank_code
      t.string :v_account
      t.datetime :expire_date

      t.timestamps
    end
  end
end
