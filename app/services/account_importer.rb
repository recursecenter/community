require 'open-uri'
require 'json'

class AccountImporter
  def import_all
    open("#{HackerSchool.site}/api/v1/people?secret_token=#{HackerSchool.secret_token}") do |f|
      JSON.parse(f.read).each do |user_data|
        User.create_or_update_from_api_data(user_data)
      end
    end
  end
end
