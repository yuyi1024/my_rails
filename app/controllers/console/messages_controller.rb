class Console::MessagesController < ApplicationController
  def index
    @messages = Message.all

    if params[:search].present?
      @messages = @messages.where(user_id: User.find_by(email: params[:email]).id) if params[:email].present?
    
      @messages = @messages.where(ApplicationController.keyword_split(['question', 'answer'], params[:keyword])) if params[:keyword].present?

      if params[:date_b].present? || params[:date_f].present?
        params[:date_f] = Time.now if !params[:date_f].present?
        params[:date_b] = Date.new(2018, 1, 1) if !params[:date_b].present?
        @messages = @messages.where(:created_at => params[:date_b].to_date..params[:date_f].to_date+1.days)
      end

      if params[:status].present?
        if params[:status].include? 'true'
          if !params[:status].include? 'false'
            @messages = @messages.where.not(answer: [nil, '']) 
          end
        elsif params[:status].include? 'false'
          @messages = @messages.where(answer: [nil, '']) 
        end
      end

      @messages = @messages.where(reply_method: params[:reply_method]) if params[:reply_method].present?
      @messages = @messages.order(params[:sort_item] + ' ' + params[:sort_order])
    
      @action = 'index'
      render 'console/messages/messages.js.erb'
    end

    @messages = @messages.order('created_at DESC')

  end
end



