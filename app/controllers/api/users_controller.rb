class Api::UsersController < Api::ApiController
  skip_authorization_check only: :deactivate
  skip_before_action :verify_authenticity_token, only: :deactivate
  skip_before_action :require_login, only: :deactivate

  authorize_resource except: :deactivate

  before_action :authorize_using_hacker_school_secret_token, only: :deactivate

  def me
  end

  def deactivate
    user = User.find_by!(hacker_school_id: params[:rc_id])

    user.deactivate
  end

  private

  def authorize_using_hacker_school_secret_token
    if HackerSchool.secret_token != params[:secret_token]
      render json: {message: 'not_found'}, status: 404
    end
  end
end
