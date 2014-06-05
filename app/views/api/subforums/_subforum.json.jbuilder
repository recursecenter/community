json.extract! subforum, :name, :id
json.threads do
  json.array! subforum.threads.order(last_posted_to: :desc) do |thread|
    json.extract! thread, :title, :id
    json.last_posted_to thread.last_posted_to.to_i
    json.created_by thread.created_by.name
    json.unread thread.unread_for?(current_user)
  end
end
