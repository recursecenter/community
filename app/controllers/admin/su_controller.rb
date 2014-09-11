class Admin::SuController < AdminController
  protect_from_forgery with: :exception
  def create
    user = User.where(id: params['user_id']).first
    session[:user_id] = user.id if user
    redirect_to root_path
  end
end
