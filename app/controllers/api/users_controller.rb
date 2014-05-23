class Api::UsersController < Api::ApiController
  authorize_resource

  def me
  end
end
