module MentionedUsers
  extend ActiveSupport::Concern

  def mentioned_user_ids
    mention_params[:mentions] || []
  end

  def mention_params
    params.permit(mentions: [])
  end
end
