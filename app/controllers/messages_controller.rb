class MessagesController < ApplicationController
	def index
		@messages = Message.where("qanda > 0").order('qanda ASC')
		@user_messages = current_user.messages.order('created_at DESC')
	end
end