class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  before_action :authenticate_user!
  
  def show
    @user = current_user
    authorize! :manage, @user
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  

  def update_field #會員中心資料更新
    @user = current_user
    @user.update(user_params)
    @action = 'update_field'
    render :template => 'devise/registrations/registrations.js.erb'
  end

  def pwd_field #會員中心更改密碼
    @user = current_user
    @action = 'pwd_field'
    render :template => 'devise/registrations/registrations.js.erb'
  end

  # def update #update pwd
  #   super
  #   redirect_to root_path
  # end

  def update
    
    #current_user
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
      render :template => 'devise/registrations/registrations.js.erb'
    else
      clean_up_passwords resource
      set_minimum_password_length

      # respond_with resource
      @action = 'update_failed'
      render :template => 'devise/registrations/registrations.js.erb'
    end
  end

  def order_list #會員中心訂單列表
    @orders = current_user.orders.order('created_at DESC')
    @orders.map{|order| order.ecpay_trade_info if !order.ecpay_logistics_id.blank?}
  end

  def favorite_list #會員中心追蹤列表
    @favorites = current_user.favorites
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
