#
# {subforum_group_name => [[subforum_name, ui_color], ...], ...}
#
subforum_groups = {
  "Recurse Center" => [["General",       "rgb(121,109,203)", [:everyone, :full_hacker_schooler],
                       "General-interest discussion about the Recurse Center or things that Recursers might find interesting."],
                      ["397 Bridge",  "rgb(91,182,159)",  [:everyone, :full_hacker_schooler],
                       "Announcements and discussion specific to those currently attending the Recurse Center."],
                      ["Welcome",       "#008C9E",          [:everyone],
                       "Welcome to the Recurse Center! Introductions, questions, and announcements for those preparing to attend the Recurse Center."],
                      ["Housing",       "#08A39B",          [:everyone],
                       "Resources, tips, and listings for Recursers in NYC."],
                      ["Programming",       "rgb(153,191,107)", [:everyone, :full_hacker_schooler],
                       "Programming, becoming a better programmer, and other things related to programming."]],

  "Regions" =>       [["New York",      "rgb(167,106,185)", [:everyone, :full_hacker_schooler],
                       "For Recursers in NYC. Events, meetups, etc."],
                      ["San Francisco", "rgb(187,103,162)", [:everyone, :full_hacker_schooler],
                       "For Recursers in San Francisco. Events, meetups, etc."],
                      ["Europe",        "rgb(197,93,131)",  [:everyone, :full_hacker_schooler],
                       "For Recursers in Europe. Events, meetups, etc."],
                      ["Midwest",       "rgb(230,110,110)", [:everyone, :full_hacker_schooler],
                       "For Recursers in the Midwest. Events, meetups, etc."]],

  "Community" =>     [["Meta",          "rgb(211,94,76)",   [:everyone, :full_hacker_schooler],
                       "Discussion about the Recurse Center's use of Community."],
                      ["Development",   "rgb(225,140,67)",  [:everyone, :full_hacker_schooler],
                       "Discussion about Community's development."]]
}

roles = [:everyone, :full_hacker_schooler, :admin]

roles.each do |role|
  Role.create(name: role)
end

groups = ["Everyone", "Current Recursers", "Faculty"]
groups.each do |group|
  Group.create(name: group)
end

users = [
  {first_name: "Carl", last_name: "Sagan", email: "carl@palebluedot.com"},
  {first_name: "Albert", last_name: "Einstein", email: "albert@relativity.net"},
  {first_name: "Marie", last_name: "Curie", email: "marie@halflife.org"},
  {first_name: "Aung", last_name: "San Sui", email: "aungsui@liberation.org"}
]

users.each do |user|
  user = User.create user
  user.groups = [Group.everyone, Group.current_hacker_schoolers, Group.faculty]
  user.roles << Role.all
  user.save!
end

subforum_groups.each do |subforum_group_name, subforums|
  group = SubforumGroup.create(name: subforum_group_name)
  subforums.each do |(subforum_name, ui_color, required_roles, description)|
    group.subforums.create(name: subforum_name,
                           ui_color: ui_color,
                           required_role_ids: Role.where(name: required_roles).map(&:id),
                           description: description)
  end
end
