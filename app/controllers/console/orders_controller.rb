class Console::OrdersController < ApplicationController
	
	def index
		@orders = Order.includes(:user)
		@orders = @orders.where(process_id: params[:process_id]) if params[:process_id].present?
		@orders = @orders.where(:users => { :email => params[:email] }) if params[:email].present?
		@orders = @orders.where(status: params[:status]) if params[:status].present?
		@orders = @orders.where(pay_method: params[:pay_method]) if params[:pay_method].present?
		@orders = @orders.where(ship_method: params[:ship_method]) if params[:ship_method].present?

		render 'console/orders/index.js.erb' if params[:search].present?

	end

	def show

	end

	def edit

	end

	def update

	end

end

