#
# {subforum_group_name => [[subforum_name, ui_color], ...], ...}
#
subforum_groups = {
  "Hacker School" => [["General",       "rgb(121,109,203)", [:everyone, :full_hacker_schooler],
                       "General-interest discussion about Hacker School or things that Hacker Schoolers might find interesting."],
                      ["455 Broadway",  "rgb(91,182,159)",  [:everyone, :full_hacker_schooler],
                       "Announcements and discussion specific to those currently attending Hacker School."],
                      ["Welcome",       "#008C9E",          [:everyone],
                       "Welcome to Hacker School! Introductions, questions, and announcements for those preparing to attend Hacker School."],
                      ["Housing",       "#08A39B",          [:everyone],
                       "Resources, tips, and listings for Hacker Schoolers in NYC."]],

  "Programming" =>   [["General",       "rgb(153,191,107)", [:everyone, :full_hacker_schooler],
                       "Programming, becoming a better programmer, and other things related to programming."]],

  "Regions" =>       [["New York",      "rgb(167,106,185)", [:everyone, :full_hacker_schooler],
                       "For Hacker Schoolers in NYC. Events, meetups, etc."],
                      ["San Francisco", "rgb(187,103,162)", [:everyone, :full_hacker_schooler],
                       "For Hacker Schoolers in San Francisco. Events, meetups, etc."],
                      ["Europe",        "rgb(197,93,131)",  [:everyone, :full_hacker_schooler],
                       "For Hacker Schoolers in Europe. Events, meetups, etc."],
                      ["Midwest",       "rgb(230,110,110)", [:everyone, :full_hacker_schooler],
                       "For Hacker Schoolers in the Midwest. Events, meetups, etc."]],

  "Community" =>     [["Meta",          "rgb(211,94,76)",   [:everyone, :full_hacker_schooler],
                       "Discussion about Hacker School's use of Community."],
                      ["Development",   "rgb(225,140,67)",  [:everyone, :full_hacker_schooler],
                       "Discussion about Community's development."]]
}

roles = [:everyone, :full_hacker_schooler, :admin]

roles.each do |role|
  Role.create(name: role)
end

users = [
  {:first_name => "David", :last_name => "Albert", :email => "dave@hackerschool.com"},
  {:first_name => "Nick", :last_name => "Bergson-Shilcock", :email => "nick@hackerschool.com"},
  {:first_name => "Sonali", :last_name => "Sridhar", :email => "sonali@hackerschool.com"}
]

users.each do |user|
  user = User.create :first_name => user[:first_name], :last_name => user[:last_name], :email => user[:email]
  user.groups = [Group.everyone]
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
