json.extract! subforum_group, :name, :id
json.subforums do
  json.array! subforum_group.subforums_with_visited_status.order(id: :asc) do |subforum|
    json.extract! subforum, :id, :name
    json.unread subforum.unread?
  end
end
