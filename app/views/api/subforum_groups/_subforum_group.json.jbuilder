json.extract! subforum_group, :name, :id
json.subforums subforum_group.subforums, :id, :name
