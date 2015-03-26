class BatchNotificationJob
  def initialize(method, users, *args)
    @ids = users.map(&:id)
    @method = method
    @args = args
  end

  def perform
    User.where(id: @ids).each do |u|
      NotificationMailer.send(@method, u, *@args).deliver
    end
  end
end
