class BatchNotificationJob
  def initialize(method, users, *args)
    @ids = users.map(&:id)
    @method = method
    @args = args
  end

  def perform
    # Mailgun has a maximum of 1,000 recipients per message. We're
    # doing 999 just to be safe.
    User.where(id: @ids).in_batches(of: 999) do |users|
      NotificationMailer.send(@method, users, *@args).deliver_now
    end
  end
end
