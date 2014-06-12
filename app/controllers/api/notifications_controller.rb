class Api::NotificationsController < Api::ApiController
  load_and_authorize_resource :notification

  def read
    @notification.update!(read: true)
    render json: {}
  end
end
