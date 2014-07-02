json.extract! subforum_group, :name, :id
json.subforums do
  json.array! subforum_group.subforums_for_user(current_user).order(id: :asc) do |subforum|
    json.extract! subforum, :id, :name, :slug
    json.unread subforum.unread?
  end
end
