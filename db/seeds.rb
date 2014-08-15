#
# {subforum_group_name => [[subforum_name, ui_color], ...], ...}
#
subforum_groups = {
  "Hacker School" => [["General",       "rgb(121,109,203)", [:everyone, :full_hacker_schooler]],
                      ["Events",        "rgb(109,160,203)", [:everyone, :full_hacker_schooler]],
                      ["455 Broadway",  "rgb(91,182,159)",  [:everyone, :full_hacker_schooler]],
                      ["Welcome",       nil,                [:everyone]],
                      ["Housing",       nil,                [:everyone]]],

  "Programming" =>   [["General",       "rgb(153,191,107)", [:everyone, :full_hacker_schooler]]],

  "Regions" =>       [["New York",      "rgb(167,106,185)", [:everyone, :full_hacker_schooler]],
                      ["San Francisco", "rgb(187,103,162)", [:everyone, :full_hacker_schooler]],
                      ["Europe",        "rgb(197,93,131)",  [:everyone, :full_hacker_schooler]]],

  "Community" =>     [["Meta",          "rgb(211,94,76)",   [:everyone, :full_hacker_schooler]],
                      ["Development",   "rgb(225,140,67)",  [:everyone, :full_hacker_schooler]]]
}

roles = [:everyone, :full_hacker_schooler, :admin]

roles.each do |role|
  Role.create(name: role)
end

subforum_groups.each do |subforum_group_name, subforums|
  group = SubforumGroup.create(name: subforum_group_name)
  subforums.each do |(subforum_name, ui_color, required_roles)|
    group.subforums.create(name: subforum_name,
                           ui_color: ui_color,
                           required_role_ids: Role.where(name: required_roles).map(&:id))
  end
end
