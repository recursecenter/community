json.extract! subforum, :name, :id, :slug
json.threads do
  json.array! threads do |thread|
    json.extract! thread, :title, :id, :slug
    json.marked_unread_at thread.marked_unread_at.to_i
    json.created_by thread.created_by.name
    json.unread thread.unread?
  end
end
json.autocomplete_users @autocomplete_users, :id, :first_name, :last_name
json.broadcast_groups Group.all, :id, :name
