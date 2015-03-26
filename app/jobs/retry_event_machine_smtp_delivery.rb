require 'event_machine_smtp_delivery'

class RetryEventMachineSmtpDelivery
  def initialize(em_smtp_options, attempt_number, max_retries)
    @em_smtp_options = em_smtp_options
    @attempt_number = attempt_number
    @max_retries = max_retries
  end

  def perform
    EventMachineSmtpDelivery.send_smtp(@em_smtp_options, @attempt_number, @max_retries)
  end
end

