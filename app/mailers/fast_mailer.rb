class FastMailer < ActionMailer::Base
  def test_email(user)
    @user = user

    headers[EventMachineSmtpDelivery::CUSTOM_RCPT_TO_HEADER] = user.email

    mail(to: 'mailing-list@example.com',
         from: 'dave@example.com',
         subject: "This is a test email",
         body: "Hello test from inside ruby")
  end
end
