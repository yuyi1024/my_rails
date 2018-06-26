class Console::MessagesController < Console::DashboardsController
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

      if params[:qanda].present?
        if params[:qanda].include? 'true'
          if !params[:qanda].include? 'false'
            @messages = @messages.where('qanda >= 0') 
          end
        elsif params[:qanda].include? 'false'
          @messages = @messages.where(qanda: [nil, '']) 
        end
      end

      @messages = @messages.where(reply_method: params[:reply_method]) if params[:reply_method].present?
      @messages = @messages.order(params[:sort_item] + ' ' + params[:sort_order])
      kaminari_page
      
      @action = 'index'
      render 'console/messages/messages.js.erb'
    end
    
    @messages = @messages.order('created_at DESC')
    kaminari_page
  end

  def edit
    @message = Message.find(params[:id])
  rescue StandardError => e
    redirect_to(console_messages_path, alert: "發生問題：#{e}")
  end

  def update
    @message = Message.find(params[:id])
    @message.update(message_params)
    
    if @message.save
      if @message.reply_method == 'email'
        UserMailer.message_email(@message).deliver_now
      end
      flash[:success] = '訊息已回覆'
    else
      flash[:alert] = '訊息回覆失敗'
    end
    redirect_to edit_console_message_path(@message)

  rescue StandardError => e
    flash[:alert] = "發生問題：#{e}"
    redirect_to console_messages_path
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    flash[:success] = '刪除成功'
    redirect_to console_messages_path
  end

  def qanda
    @message = Message.new
    @qandas = Message.where('qanda > 0').order('qanda ASC')
    @qusetions = Message.where(qanda: 0)
  end

  def create
    @message = Message.create(qanda_params)
    @message.user = current_user
    @message.qanda = 0
    @message.reply_method = 'message'

    if @message.save
      flash[:success] = '新增成功，請於右側將新增的問題拖曳至下方區塊'
      redirect_to qanda_console_messages_path
    end
  end

  def sort_qanda
    if params[:qanda].present?
      params[:qanda].each_with_index do |item, index|
        qanda = Message.find(item.to_i)
        qanda.qanda = index + 1
        qanda.save
      end
    end

    if params[:holding].present?
      params[:holding].each do |item|
        qanda = Message.find(item.to_i)
        qanda.qanda = 0
        qanda.save
      end
    end
    flash[:success] = '更新成功'
    redirect_to qanda_console_messages_path
  end

  def kaminari_page #分頁
    @rows = @messages.length
    params[:page] = 1 if !params[:page].present?
    @messages = @messages.page(params[:page]).per(25)
  end




  private

  def message_params
    params.require(:message).permit(:question, :answer)
  end

  def qanda_params
    params.require(:message).permit!
  end
end



