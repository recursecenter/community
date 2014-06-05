json.extract! subforum, :name, :id
json.threads do
  json.array! threads do |thread|
    json.extract! thread, :title, :id
    json.last_posted_to thread.last_posted_to.to_i
    json.created_by thread.created_by.name
    json.unread thread.unread?
  end
end
