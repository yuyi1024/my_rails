class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  # before_action :authenticate_user!
  before_action :can_manage_user?, except: [:new, :create]

  def can_manage_user?
    @user = current_user
    authorize! :manage, @user
  end
  
  def show # 會員資料
  rescue StandardError => e
    redirect_to(root_path, alert: "發生錯誤：#{e}")
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create # 註冊
    params[:user][:role] = 'member'
    super
  end

# Password confirmation translation missing: zh.activerecord.errors.models.user.attributes.password_confirmation.confirmation

  # GET /resource/edit
  # def edit 
  #   super
  # end

  # PUT /resource
  
  def update_field # 會員資料-資料更新
    @user.update(user_params)
    @action = __method__.to_s
    render 'devise/registrations/registrations.js.erb'
  end

  def pwd_field # 會員資料-顯示密碼更改欄位
    @action = __method__.to_s
    render 'devise/registrations/registrations.js.erb'
  end

  def update # 會員資料-密碼更新
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
    resource_updated = update_resource(resource, account_update_params) #true/false
    yield resource if block_given?

    if resource_updated
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      bypass_sign_in resource, scope: resource_name
      # respond_with resource, location: after_update_path_for(resource)
      @action = 'update_success'
      render 'devise/registrations/registrations.js.erb'
    else
      clean_up_passwords resource
      set_minimum_password_length

      # respond_with resource
      @action = 'update_failed'
      render 'devise/registrations/registrations.js.erb'
    end
  rescue StandardError => e
    redirect_to(user_show_path, alert: "發生錯誤：#{e}")
  end

  def order_list # 會員中心訂單列表
    @orders = @user.orders.order('created_at DESC')
    @orders.map{|order| order.ecpay_trade_info if !order.ecpay_logistics_id.blank?}
    
    # 訂單狀態 select_box
    status_hash = JSON.parse(File.read('app/assets/javascripts/order_status.json'))
    @status_arr = []
    status_hash['OrderStatus'].map{|s| @status_arr << [s['cn'],s['status']]}
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "發生錯誤：#{e}")
  end

  def order_status_select # 訂單列表選擇 status
    @orders = current_user.orders
    @orders = @orders.where(status: params[:status]) if params[:status] != 'all'
    @action = __method__.to_s
    render 'devise/registrations/registrations.js.erb'
  end

  def favorite_list # 會員中心追蹤列表
    @favorites = @user.favorites
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "發生錯誤：#{e}")
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  # end

  def user_params
    params.require(:user).permit!
  end


  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
