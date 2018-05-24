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

  def edit
    @message = Message.find(params[:id])
  end

  def update
    @message = Message.find(params[:id])
    @message.update(message_params)
    
    if @message.save
      if @message.reply_method == 'email'
        UserMailer.message_email(@message).deliver_now
      end
      flash[:notice] = '訊息已發送'
    else
      flash[:notice] = '訊息發送失敗'
    end
    redirect_to edit_console_message_path(@message)

  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    redirect_to console_messages_path
  end

  private
  def message_params
    params.require(:message).permit(:answer)
  end
end



