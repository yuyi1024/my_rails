class MessagesController < ApplicationController
  before_action :cart_show, only: [:index]
  before_action :order_pending, only: [:index]

	def index # 聯絡我們
		@messages = Message.where("qanda > 0").order('qanda ASC')
		if current_user
			@user_messages = current_user.messages.order('created_at DESC')
			@message = Message.new
		end
	end

	def create # 發問
		@message = current_user.messages.create(question: message_params[:question])

		# 以信箱回覆問題
		if message_params[:reply_method] == '1'
			@message.reply_method = 'email'
			@message.email = message_params[:email]
		end

		if @message.save
			flash[:success] = '訊息發送成功，請耐心等待回覆'
			redirect_to messages_path
		else
			raise StandardError, '訊息發送失敗，請再嘗試一次'
		end
	rescue StandardError => e
		redirect_back(fallback_location: messages_path, alert: "#{e}")
	end

	private

	def message_params
		params.require(:message).permit!
	end
end