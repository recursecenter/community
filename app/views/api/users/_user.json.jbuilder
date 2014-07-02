json.extract! user, :id, :first_name, :last_name, :email, :avatar_url, :batch_name, :hacker_school_id
json.settings do
  json.extract! user, :email_on_mention
end
