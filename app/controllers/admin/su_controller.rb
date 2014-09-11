class Admin::SuController < AdminController
  protect_from_forgery with: :exception

  def index
    @su_users = User.all.order(:first_name)
  end

  def create
    user = User.where(id: params['user_id']).first
    session[:user_id] = user.id if user
    redirect_to root_path
  end
end
