class TestMailJob
  def perform
    User.all.each do |u|
      FastMailer.test_email(u).deliver
    end
  end
end
