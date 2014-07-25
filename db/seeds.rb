#
# {subforum_group_name => [[subforum_name, ui_color], ...], ...}
#
subforum_groups = {
  "Hacker School" => [["General",       "rgb(121,109,203)"],
                      ["Events",        "rgb(109,160,203)"],
                      ["455 Broadway",  "rgb(91,182,159)"]],

  "Programming" =>   [["General",       "rgb(153,191,107)"]],

  "Regions" =>       [["New York",      "rgb(167,106,185)"],
                      ["San Francisco", "rgb(187,103,162)"],
                      ["Europe",        "rgb(197,93,131)"]],

  "Community" =>     [["Meta",          "rgb(211,94,76)"],
                      ["Development",   "rgb(225,140,67)"]]
}

subforum_groups.each do |subforum_group_name, subforums|
  group = SubforumGroup.create(name: subforum_group_name)
  subforums.each do |(subforum_name, ui_color)|
    group.subforums.create(name: subforum_name, ui_color: ui_color)
  end
end
