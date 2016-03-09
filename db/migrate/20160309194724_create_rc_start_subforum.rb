class CreateRcStartSubforum < ActiveRecord::Migration
  def up
    g = SubforumGroup.create!(name: "RC Start")
    f = g.subforums.create!(
      name: "RC Start",
      required_role_ids: [Role.rc_start.id],
      description: "Discussion about programming and becoming a better programmer for RC Start participants, mentors, and anyone else.",
      ui_color: "#c7d83d"
    )
  end

  def down
    Subforum.where(name: "RC Start").destroy_all
    SubforumGroup.where(name: "RC Start").destroy_all
  end
end
