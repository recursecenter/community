if Rails.env.production? && !ENV.has_key?('MAILGUN_API_KEY')
  raise 'You must set ENV["MAILGUN_API_KEY"] in production.'
end
