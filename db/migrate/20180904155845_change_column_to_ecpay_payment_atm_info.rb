class ChangeColumnToEcpayPaymentAtmInfo < ActiveRecord::Migration[5.1]
  def change
    remove_column :ecpay_payment_atm_infos, :expire_date
    add_column :ecpay_payment_atm_infos, :expire_date, :date, after: :v_account
    add_column :ecpay_payment_atm_infos, :paid, :boolean, after: :expire_date, default: false
  end
end
