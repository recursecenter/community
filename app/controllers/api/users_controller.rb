class Api::UsersController < Api::ApiController
  def me
    render json: {message: "it works!"}
  end
end
