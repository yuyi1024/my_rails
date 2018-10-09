class Console::OrdersController < Console::DashboardsController
  
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
        @orders = @orders.where(status: params[:status]) 
      end

      @orders = @orders.where(pay_method: params[:pay_method]) if params[:pay_method].present?
      @orders = @orders.where(ship_method: params[:ship_method]) if params[:ship_method].present?

      if params[:paid].present?
        paid = params[:paid]
        paid += [nil] if params[:paid].include?('false')
        @orders = @orders.where(paid: paid)
      end

      if params[:shipped].present?
        shipped = params[:shipped]
        shipped += [nil] if params[:shipped].include?('false')
        @orders = @orders.where(shipped: shipped)
      end

      if params[:sort_item].present? && params[:sort_order].present?
        @orders = @orders.order('orders.' + params[:sort_item] + ' ' + params[:sort_order])
      end
      kaminari_page
      
      @action = 'index'
      render 'console/orders/orders.js.erb' 
    else
      @orders = @orders.order("created_at DESC")
      @orders.map{|order| 
        order.ecpay_trade_info if order.status == 'waiting_shipment' && order.shipment_no.blank?
      }
      kaminari_page
    end
  end

  def edit
    @order = Order.find_by(process_id: params[:id])

    if @order.ecpay_logistics_id.present?
      msg = @order.ecpay_trade_info
      if !msg.present?
        @logistics_status = '無資訊'
      else
        @logistics_status = msg[0]['message']        
      end
    else
      @logistics_status = '未出貨'
    end
    
    @may_status = @order.may_status
    
    if @order.status == 'waiting_refunded'
      # 通知已退款資料表單
      @remittance_info = RemittanceInfo.new
      # 買家退款資料(未退款)
      @refund_info = @order.remittance_infos.where(refunded: false).order('created_at DESC').first
    end
    # 成功退款資料
    @refunded_success = @order.remittance_infos.where(refunded: true).order('created_at DESC').first if @order.status == 'canceled'

  rescue StandardError => e
    redirect_to(console_orders_path, alert: "發生錯誤：#{e}")
  end

  def update
    @order = Order.find_by(process_id: params[:id])
    
    if params[:order][:status] != '0'
      # 根據選擇的 status 改變訂單狀態
      @order.method(params[:order][:status]).call
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

  # 通知買家已退款
  def refund
    @order = Order.find_by(process_id: params[:process_id])
    @refund = @order.remittance_infos.where(refunded: false).order('created_at DESC').first
    @refund.update(remittance_info_params)
    @refund.refunded = true
    @order.refund
    if @refund.save && @order.save
      flash[:success] = '退款通知成功'
      redirect_to edit_console_order_path(@order.process_id)
    else
      raise StandardError, '退款通知失敗'
    end
    rescue StandardError => e
      redirect_to(edit_console_order_path(@order.process_id), alert: "發生錯誤：#{e}")
  end

  private

  def kaminari_page # 分頁
    @rows = @orders.length
    params[:page] = 1 if !params[:page].present?
    @orders = @orders.page(params[:page]).per(25)
  end

  def remittance_info_params
    params.require(:remittance_info).permit!
  end

end