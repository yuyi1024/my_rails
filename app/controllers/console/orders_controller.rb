class Console::OrdersController < ApplicationController
  before_action :dashboard_authorize
  
  def index

    @orders = Order.includes(:user)

    if params[:search].present?
      @orders = @orders.where(process_id: params[:process_id]) if params[:process_id].present?
      @orders = @orders.where(:users => { :email => params[:email] }) if params[:email].present?
      
      if params[:date_b].present? || params[:date_f].present?
        params[:date_f] = Time.now if !params[:date_f].present?
        params[:date_b] = Date.new(2018, 1, 1) if !params[:date_b].present?
        @orders = @orders.where(:created_at => params[:date_b].to_date..params[:date_f].to_date+1.days)
      end

      if params[:status].present?
        params[:status] << 'paid' if params[:status].include?('waiting_shipment')
        @orders = @orders.where(status: params[:status]) 
      end

      @orders = @orders.where(pay_method: params[:pay_method]) if params[:pay_method].present?
      @orders = @orders.where(ship_method: params[:ship_method]) if params[:ship_method].present?

      if params[:paid].present?
        paid = []
        paid << 'true' if params[:paid].include?('true')
        paid += ['false', nil] if params[:paid].include?('false')
        paid << 'remit' if params[:paid].include?('remit')
        @orders = @orders.where(paid: paid)
      end

      if params[:delivered].present?
        delivered = []
        delivered << 'true' if params[:delivered].include?('true')
        delivered += ['false', nil] if params[:delivered].include?('false')
        @orders = @orders.where(delivered: delivered)
      end

      if params[:sort_item].present? && params[:sort_order].present?
        @orders = @orders.order('orders.' + params[:sort_item] + ' ' + params[:sort_order])
      end
      kaminari_page
      
      @action = 'index'
      render 'console/orders/orders.js.erb' 
    else
      @orders = @orders.order("created_at DESC")
      @orders.map{|order| order.ecpay_trade_info if !order.ecpay_logistics_id.blank?}
      kaminari_page
    end
  end

  def edit
    @order = Order.find_by(process_id: params[:id])
    
    if @order.ecpay_logistics_id.present?
      @logistics_status = @order.ecpay_trade_info
      @logistics_status = @logistics_status.message
    else
      @logistics_status = '未出貨'
    end
    @may_status = @order.may_status
    @remit_data = @order.remit_data.split('/') if !@order.remit_data.blank?

  rescue StandardError => e
    redirect_to(console_orders_path, alert: "發生錯誤：#{e}")
  end

  def update
    @order = Order.find_by(process_id: params[:id])
    
    if params[:order][:status] != '0'
      @order.method(params[:order][:status]).call
      if params[:order][:status] == 'pay'
        @order.paid = 'true'
        hash = @order.ecpay_create
        @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]
      end
    else
      raise StandardError, '未選擇欲更改的狀態'
    end
    
    if @order.save
      flash[:success] = '訂單狀態更改成功'
    else
      raise StandardError, '訂單狀態更改失敗'
    end

  rescue StandardError => e
    flash[:alert] = "發生錯誤：#{e}"
  ensure
    redirect_to edit_console_order_path
  end

  #付款資訊有誤，取消付款通知
  def remit_check
    @order = Order.find_by(process_id: params[:process_id])
    @order.paid = 'false'
    @order.status = 'waiting_payment'
    @order.remit_data = ''
    
    if @order.save
      flash[:success] == '取消付款通知'
      redirect_to edit_console_order_path(@order.process_id)
    else
      raise StandardError, '付款通知更動失敗'
    end

  rescue StandardError => e
    redirect_to(console_orders_path, alert: "發生錯誤：#{e}")
  end

  def dashboard_authorize
    authorize! :dashboard, Order
  end

  def kaminari_page #分頁
    @rows = @orders.length
    params[:page] = 1 if !params[:page].present?
    @orders = @orders.page(params[:page]).per(25)
  end

end