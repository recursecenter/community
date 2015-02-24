class FastMailer < ActionMailer::Base
  def test_email(user)
    @user = user

    mail(to: 'test@example.com',
         from: user.email,
         subject: "This is a test email",
         body: "Hello test from inside ruby")
  end
end
