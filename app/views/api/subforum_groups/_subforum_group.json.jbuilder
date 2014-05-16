json.extract! subforum_group, :name
json.subforum_ids subforum_group.subforums.map(&:id)
