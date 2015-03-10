class BatchNotificationSender
  def self.deliver(method, recipient_variables, *args, &block)
    mail = NotificationMailer.send(method, *args, &block)
    BatchMailSender.new(mail, recipient_variables).deliver
  end
end
