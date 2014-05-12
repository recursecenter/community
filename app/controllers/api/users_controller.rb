class Api::UsersController < Api::ApiController
  def me
    render json: {first_name: current_user.first_name}
  end
end
