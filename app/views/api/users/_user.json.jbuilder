json.extract! user, :id, :first_name, :last_name, :email, :avatar_url, :batch_name, :hacker_school_id

json.settings do
  json.extract! user, :email_on_mention, :subscribe_when_mentioned, :subscribe_on_create, :subscribe_new_thread_in_subscribed_subforum
end
