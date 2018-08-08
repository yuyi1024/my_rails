class MessagesController < ApplicationController
	def index
		@messages = Message.where("qanda > 0").order('qanda ASC')

		if current_user
			@user_messages = current_user.messages.order('created_at DESC')
			@message = Message.new
		end
	end

	def create
		@message = Message.create(question: message_params[:question])
		@message.user = current_user

		if message_params[:reply_method] == '1'
			@message.reply_method = 'email'
			@message.email = message_params[:email]
		end

		if @message.save
			flash[:success] = '訊息發送成功，請耐心等待回覆'
		else
			flash[:alert] = '訊息發送失敗，請再嘗試一次'
		end
		redirect_to messages_path
	end

	private

	def message_params
		params.require(:message).permit!
	end
end