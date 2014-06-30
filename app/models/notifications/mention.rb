class Notifications::Mention < Notification
  validates :mentioned_by, :post, presence: true

  belongs_to :mentioned_by, class_name: "User"
  belongs_to :post

  def to_builder
    Jbuilder.new do |json|
      json.extract! self, :id, :read

      json.type "mention"
      json.created_at created_at.to_i

      json.mentioned_by do
        json.extract! mentioned_by, :first_name, :last_name
      end

      json.thread do
        json.extract! post.thread, :id, :title
      end

      json.post do
        json.id post.id
      end
    end
  end
end
