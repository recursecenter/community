class Notification < ActiveRecord::Base
  validates :user, presence: true

  belongs_to :user

  scope :unread, -> { where(read: false) }
end
