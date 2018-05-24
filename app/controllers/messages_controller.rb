class MessagesController < ApplicationController
	def index
		@messages = Message.where("qanda > 0").order('qanda ASC')
		@user_messages = current_user.messages.order('created_at DESC')
		@message = Message.new
	end

	def create
		@message = Message.create(question: message_params[:question])
		@message.user = current_user

		if message_params[:reply_method] == '1'
			@message.reply_method = 'email'
			@message.email = message_params[:email]
		end

		if @message.save
			@action = 'create'
			render 'messages/messages.js.erb'
		end

	end

	private

	def message_params
		params.require(:message).permit!
	end
end