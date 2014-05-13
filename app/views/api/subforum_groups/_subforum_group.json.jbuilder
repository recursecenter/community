json.extract! subforum_group, :name
json.subforums do
  json.array! subforum_group.subforums do |subforum|
    json.extract! subforum, :name
  end
end
