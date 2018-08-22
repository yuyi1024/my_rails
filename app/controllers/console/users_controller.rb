class Console::UsersController < Console::DashboardsController
  def index
    @users = User.all

    if params[:search].present?
      @users = @users.where(keyword_split(['email'], params[:email])) if params[:email].present?
      @users = @users.where(keyword_split(['name', 'true_name', 'address'], params[:keyword])) if params[:keyword].present?
      @users = @users.where(role: params[:role]) if params[:role].present?
      if params[:confirm].present?
        @users = (params[:confirm].include?('true') ? @users.where.not(confirmed_at: nil) : @users.where(confirmed_at: nil))
      end

      if params[:sort_item].present? && params[:sort_order].present?
        @users = @users.reorder(params[:sort_item] + ' ' + params[:sort_order])
      end

      kaminari_page

      @action = 'search'
      render 'console/users/users.js.erb'
    else
      @users = @users.order('role ASC')
    end

    kaminari_page
  end

  def show
    @user = User.find(params[:id])
    @orders = @user.orders.order('created_at DESC')
  rescue StandardError => e
    redirect_to(console_users_path, alert: "發生錯誤：#{e}")
  end

  def update
    authorize! :manage_role, @user

    @user = User.find(params[:id])
    @user.role = params[:user][:role]

    if @user.save
      flash[:success] = '更新成功'
    else
      flash[:alert] = '更新失敗'
    end
    redirect_to console_user_path(@user)
  rescue StandardError => e
    redirect_to(console_users_path, alert: "發生錯誤：#{e}")
  end

  private

  def kaminari_page #分頁
    @rows = @users.length
    params[:page] = 1 if !params[:page].present?
    @users = @users.page(params[:page]).per(25)
  end

end