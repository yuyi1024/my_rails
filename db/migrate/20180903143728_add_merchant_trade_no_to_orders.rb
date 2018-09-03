class AddMerchantTradeNoToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :merchant_trade_no, :string, after: :process_id
  end
end
