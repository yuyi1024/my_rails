class Console::MessagesController < Console::DashboardsController
  def index
    @messages = Message.includes(:user)
    if params[:search].present?
      @messages = @messages.where(users: {email: params[:email]}) if params[:email].present?
      @messages = @messages.where(keyword_split(['question', 'answer'], params[:keyword], 'messages')) if params[:keyword].present?

      if params[:date_b].present? || params[:date_f].present?
        params[:date_f] = Time.now if !params[:date_f].present?
        params[:date_b] = Date.new(2018, 1, 1) if !params[:date_b].present?
        @messages = @messages.where(created_at: params[:date_b].to_date..params[:date_f].to_date+1.days)
      end

      if params[:status].present?
        if params[:status].include? 'true'
          @messages = @messages.where.not(answer: [nil, '']) if !params[:status].include? 'false'
        elsif params[:status].include? 'false'
          @messages = @messages.where(answer: [nil, '']) 
        end
      end

      if params[:qanda].present?
        if params[:qanda].include? 'true'  
          @messages = @messages.where('qanda >= 0') if !params[:qanda].include? 'false'
        elsif params[:qanda].include? 'false'
          @messages = @messages.where(qanda: [nil, '']) 
        end
      end

      @messages = @messages.where(reply_method: params[:reply_method]) if params[:reply_method].present?
      @action = 'index'
    end
      @messages = @messages.order('messages.' + (params[:sort_item] ||= 'created_at') + ' ' + (params[:sort_order] ||= 'DESC')) 
      @messages = kaminari_page(@messages)
      render 'console/messages/messages.js.erb' if params[:search].present?
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
      # 將回覆以 email 寄給發問者
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

  def qanda # Q&A 管理
    @message = Message.new

    messages = Message.all
    @qandas = messages.select{|m| !m.qanda.nil? && m.qanda > 0}.sort_by{|m| m.qanda}
    @qusetions = messages.select{|m| m.qanda == 0}
  end

  def create # 新增 Q&A 問題
    @message = Message.create(qanda_params)
    @message.user = current_user
    @message.qanda = 0
    @message.reply_method = 'message'

    if @message.save
      flash[:success] = '新增成功，請於右側將新增的問題拖曳至下方區塊'
      redirect_to qanda_console_messages_path
    end
  end

  def sort_qanda # Q&A 排序
    # 公開的 Q&A
    if params[:qanda].present?
      params[:qanda].each_with_index do |item, index|
        qanda = Message.find(item.to_i)
        qanda.qanda = index + 1
        qanda.save
      end
    end

    # 不公開的 Q&A
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

  private

  def message_params
    params.require(:message).permit(:question, :answer)
  end

  def qanda_params
    params.require(:message).permit!
  end
end



