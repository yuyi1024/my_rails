class UserMailer < ApplicationMailer
  default from: 'bonnie841024@gmail.com'
  # 授權存取您的 Google 帳戶
  # https://accounts.google.com/DisplayUnlockCaptcha

  def message_email(message)
    @user = message.user
    @message = message
    @url = 'https://bawan-store-0225.herokuapp.com/messages'
    mail( to: @message.email, subject: '霸雕爆裂丸-訊息回覆' )
  end
end