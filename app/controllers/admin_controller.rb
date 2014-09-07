class AdminController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  layout 'application'
  protect_from_forgery with: :exception

  include CurrentUser

  def require_admin_login
    if !current_user || !current_user.is_admin?
      redirect_to root_path
    end
  end

end