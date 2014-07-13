class BatchNotificationSender
  def self.deliver(method, *args, &block)
    mail = NotificationMailer.send(method, *args, &block)
    BatchMailSender.new(mail).deliver
  end
end
