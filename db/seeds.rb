#
# {subforum_group_name => [subforum_name, ...], ...}
#
subforum_groups = {
  'General' => ['Announcements'],
  'Attending Hacker School' => ['Welcome! Q&A', 'Housing'],
  'Programming' => ['General interest', 'Ruby', 'Python', 'JavaScript', 'Clojure'],
  'Social' => ['Meetups', 'Events', 'Off topic']
}

subforum_groups.each do |subforum_group_name, subforum_names|
  group = SubforumGroup.create(name: subforum_group_name)
  subforum_names.each do |subforum_name|
    group.subforums.create(name: subforum_name)
  end
end
