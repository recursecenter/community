module Community
  def self.client_env
    @client_env ||= if ENV["CLIENT_ENV"]
      ActiveSupport::StringInquirer.new(ENV["CLIENT_ENV"])
    else
      Rails.env
    end
  end
end
