class UserMailer < ApplicationMailer
  default from: 'bonnie_841024@gmail.com'

  def message_email(message)
    @user = message.user
    @message = message
    @url = 'http://localhost:3001/messages'
    mail( to: @user.email, subject: '霸雕爆裂丸-訊息回覆' )
  end
end