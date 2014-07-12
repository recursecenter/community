module MentionedUsers
  extend ActiveSupport::Concern

  def mentioned_users
    if mention_params[:mentions].present?
      User.where(id: mention_params[:mentions])
    else
      []
    end
  end

  def mention_params
    params.permit(mentions: [])
  end
end
