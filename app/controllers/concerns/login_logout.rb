module LoginLogout
  extend ActiveSupport::Concern

  def login(user)
    session[:user_id] = user.id
  end

  def logout
    reset_session
  end
end
