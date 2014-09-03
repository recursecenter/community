class Admin::SudoController < AdminController
  before_filter :require_admin_login

  def index
  end

  def grant
    user = User.where(:email => params['email']).first
    session[:user_id] = user.id if user
    redirect_to root_path
  end
end