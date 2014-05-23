class Api::ApiController < ApplicationController
  before_filter :require_login

  check_authorization
  rescue_from CanCan::AccessDenied do |e|
    render json: {message: 'User unauthorized for this action'}, status: :forbidden
  end

  def require_login
    unless current_user
      render json: {message: 'Login required'}, status: :forbidden
    end
  end
end
