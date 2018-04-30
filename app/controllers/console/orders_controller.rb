class Console::OrdersController < ApplicationController
	
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
			@orders = @orders.where(status: params[:status]) if params[:status].present?
			@orders = @orders.where(pay_method: params[:pay_method]) if params[:pay_method].present?
			@orders = @orders.where(ship_method: params[:ship_method]) if params[:ship_method].present?

			if params[:sort_item].present? && params[:sort_order].present?
				if params[:sort_item] == '下單日期'
					@orders = @orders.order("created_at " + params[:sort_order])
				elsif params[:sort_item] == '金額'
					@orders = @orders.order("price " + params[:sort_order])
				end
			end
			render 'console/orders/index.js.erb' 
		else
			@orders = @orders.order("created_at DESC")
		end
	end

	def edit
		@order = Order.find_by(process_id: params[:id])
		@may = []

		@may << ['已付款, 待出貨', 'pay'] if @order.may_pay?
		@may << ['已出貨', 'ship'] if @order.may_ship?
		
		@may << ['已到貨', 'deliver'] if @order.may_deliver? && @order.ship_method == 'to_address'
		@may << ['已到店', 'deliver_store'] if @order.may_deliver_store?  && @order.ship_method == 'in_store'
		@may << ['已取貨', 'pick_up'] if @order.may_pick_up?
		@may << ['結束交易', 'finish'] if @order.may_finish?
		@may << ['取消訂單', 'cancel'] if @order.may_cancel?
		@may << ['已退貨', 'return'] if @order.may_return?
		@may << ['以退款', 'refund'] if @order.may_refund?

	end

	def update
		@order = Order.find_by(process_id: params[:id])
		if params[:order][:status] != '0'
			@order.method(params[:order][:status]).call
			@order.save
			flash[:notice] = '更改成功'
		else
			flash[:alert] = '訂單狀態更改無效'
		end	
		redirect_to edit_console_order_path(@order.process_id)
	end

end