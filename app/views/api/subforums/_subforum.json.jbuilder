json.extract! subforum, :name, :id
json.threads do
  json.array! threads do |thread|
    json.extract! thread, :title, :id
    json.marked_unread_at thread.marked_unread_at.to_i
    json.created_by thread.created_by.name
    json.unread thread.unread?
  end
end
