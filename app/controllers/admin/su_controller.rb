class Admin::SuController < AdminController
  def create
    user = User.where(:email => params['email']).first
    session[:user_id] = user.id if user
    redirect_to root_path
  end
end
