class Api::ApiController < ApplicationController
  before_filter :require_login

  def require_login
    unless current_user
      render json: {message: 'Login required'}, status: :forbidden
    end
  end
end
