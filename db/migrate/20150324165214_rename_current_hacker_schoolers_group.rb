class RenameCurrentHackerSchoolersGroup < ActiveRecord::Migration
  def up
    Group.where(name: "Current Hacker Schoolers").first.update!(name: "Current Recursers")
  end

  def down
    Group.where(name: "Current Recursers").first.update!(name: "Current Hacker Schoolers")
  end
end
