class AddEcpayColumnsToOrders < ActiveRecord::Migration[5.1]
  def change
  	change_column :orders, :process_id, :string, after: :freight
  	add_column :orders, :ecpay_logistics_id, :string, after: :process_id #ecpay 交易編號
  	add_column :orders, :delivery_no, :string, after: :ecpay_logistics_id #寄貨編號/託運單號

  	rename_column :orders, :ship_method, :logistics_type #CSV/Home
  	change_column :orders, :logistics_type, :string, after: :user_id
  	add_column :orders, :logistics_subtype, :string, after: :logistics_type #超商/宅配種類

  	rename_column :orders, :true_name, :receiver_name
  	rename_column :orders, :phone, :receiver_cellphone
  	add_column :orders, :receiver_phone, :string, after: :receiver_cellphone
  	rename_column :orders, :email, :receiver_email
  	change_column :orders, :receiver_email, :string, after: :receiver_phone
  	add_column :orders, :receiver_store_id, :string, after: :receiver_email
  	rename_column :orders, :address, :receiver_address
  	change_column :orders, :receiver_address, :string, after: :receiver_store_id

  end
end