class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :name, uniqueness: true

  class << self
    [:admitted, :attended, :faculty].each do |role|
      define_method role do
        where(name: role).first_or_create!
      end
    end
  end
end
