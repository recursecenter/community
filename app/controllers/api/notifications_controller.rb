class Api::NotificationsController < Api::ApiController
  skip_authorization_check only: :read

  def read
    current_user.notifications.where(id: read_all_params[:ids]).update_all(read: true)
    render json: {}
  end

private
  def read_all_params
    params.permit(ids: [])
  end
end
