class NotificationsEmitter < PubSub::Emitter
  def created
    @notification = Notification.find(params[:id])
    render json: @notification.to_builder.attributes!
  end
end
