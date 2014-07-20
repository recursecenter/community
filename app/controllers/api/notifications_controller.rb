class Api::NotificationsController < Api::ApiController
  load_and_authorize_resource :notification, except: :read_all
  skip_authorization_check only: :read_all

  def read
    @notification.update!(read: true)
    render json: {}
  end

  def read_all
    current_user.notifications.where(id: read_all_params[:ids]).update_all(read: true)
    render json: {}
  end

private
  def read_all_params
    params.permit(ids: [])
  end
end
