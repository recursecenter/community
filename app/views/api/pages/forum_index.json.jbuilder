json.subforum_groups do
  json.array! @subforum_groups, partial: 'api/subforum_groups/subforum_group', as: :subforum_group
end

json.subforums do
  @subforum_groups.each do |subforum_group|
    subforum_group.subforums.each do |subforum|
      json.set! subforum.id do
        json.extract! subforum, :id, :name
      end
    end
  end
end
