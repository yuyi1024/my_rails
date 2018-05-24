class Message < ApplicationRecord
  belongs_to :user

  def reply_method_cn
  	case self.reply_method
  	when 'message'
  		'站內回覆'
  	when 'email'
  		'Email 回覆'
		end
  end
end
