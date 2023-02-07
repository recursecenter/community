class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :subforums, foreign_key: :required_role_id

  validates :name, uniqueness: true

  class << self
    [:pre_batch, :full_hacker_schooler, :rc_start, :admin].each do |role|
      define_method role do
        where(name: role).first_or_create!
      end
    end
  end
end
