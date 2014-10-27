class Notification < ActiveRecord::Base
  validates :user, presence: true

  belongs_to :user

  scope :unread, -> { where(read: false) }

  after_create :publish_created_notification

  def publish_created_notification
    PubSub.publish :created, :notification, self
  end
end
