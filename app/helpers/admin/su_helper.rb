module Admin::SuHelper
  def available_users
    users = User.all.select(:id, :email).map do |user|
      [user.email, user.id]
    end
  end
end