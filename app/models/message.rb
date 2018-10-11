class Message < ApplicationRecord
  belongs_to :user
  # test data 改日期
  # Message.time_rand(Time.new(2018, 9, 1), Time.now)
  def self.time_rand(from = 0.0 , to = Time.now)
    messages = Message.all.order('created_at DESC')
    messages.each do |message|
      t = Time.at(from + rand * (to.to_f - from.to_f))
      message.created_at = t - 1.days
      message.updated_at = t
      message.save
    end
  end
end
