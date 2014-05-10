class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    @current_user ||= User.where(id: session[:user_id]).first
  end

  def login(user)
    session[:user_id] = user.id
  end

  def logout
    reset_session
  end
end
