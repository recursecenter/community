class Notifications::Mention < Notification
  validates :mentioned_by, :post, presence: true

  belongs_to :mentioned_by, class_name: "User"
  belongs_to :post

  def to_builder
    Jbuilder.new do |json|
      json.type "mention"
      json.created_at created_at.to_i

      json.mentioned_by do
        json.extract! mentioned_by, :name
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
