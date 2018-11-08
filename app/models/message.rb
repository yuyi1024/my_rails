class Message < ApplicationRecord
  belongs_to :user
  # test data 改日期
  # Message.time_rand(Time.new(2018, 9, 1), Time.now)
  def self.time_rand(from = 0.0 , to = Time.now)
    messages = Message.all.order('id ASC')
    interval = ((to.to_f - from.to_f)/messages.count).round
    t = from
    messages.each do |message|
      t = Time.at(t.to_f + (interval * rand((0.5)..1)))
      message.created_at = t
      message.updated_at = t + 1.days
      message.save
    end
  end
end


