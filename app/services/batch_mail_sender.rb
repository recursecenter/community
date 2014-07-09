require 'uri'
require 'net/http'
require 'json'

# NOTE: This ignores HTML messages for the moment.
class BatchMailSender
  class Error < StandardError; end

  attr_reader :mail

  def initialize(mail)
    @mail = mail
  end

  def deliver
    if Rails.env.production?
      deliver_to_recipients
    end

    logger.info("\nSent batch message \"#{mail.subject}\"")
    logger.debug(mail.to_s)
  end

private
  def deliver_to_recipients
    url = URI("https://api:#{ENV["MAILGUN_API_KEY"]}@api.mailgun.net/v2/mail.community.hackerschool.com/messages")

    recipient_variables = mail.to.map do |addr|
      [addr, {}]
    end.to_h

    res = Net::HTTP.post_form(url,
      "to" => mail.to,
      "from" => mail.from.first,
      "subject" => mail.subject,
      "text" => mail.body.to_s,
      "recipient-variables" => JSON.generate(recipient_variables))

    unless res.code == "200"
      raise Error, "Mailgun API returned response code: #{res.code}\n#{res.body}"
    end
  end

  def logger
    ActionMailer::Base.logger
  end
end
