require 'openssl'

class Api::Private::EmailWebhooksController < Api::ApiController
  before_action :require_mailgun_origin
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  # Mailgun will POST to this endpoint when someone replies to an
  # email with a reply-to of the forms:
  #
  #     reply-(reply_info)@mail.community.recurse.com
  #     subforum-name@lists.community.recurse.com
  #
  # important params:
  #
  #     stripped-text, the plain-text email body, not including a
  #       signature or trailing quoted text
  #     timestamp, token, signature, used to verify that the POST
  #       originated from Mailgun: concat timestamp and token,
  #       encode with HMAC using Mailgun API key as the key and
  #       SHA256 digest mode, compare result to signature
  #
  # Mailgun expects a 200 for success for a 406 for not acceptable.
  # For any other code, Mailgun will retry the POST on an increasing
  # interval over the next 8 hours.
  def reply
    current_user = User.find_by(email: params["sender"])
    emailed_post = Post.find_by(message_id: params["In-Reply-To"])

    unless current_user.present? && emailed_post.present?
      head 406 and return
    end

    post = emailed_post.thread.posts.build

    unless can?(:create, post)
      head 406 and return
    end

    post.author = current_user
    post.body = params['stripped-text']
    post.message_id = params["Message-Id"]

    unless post.save
      head 406 and return
    end

    post.mark_as_visited(current_user)
    PubSub.publish :created, :post, post

    # TODO: parse and notify @mentions as well
    ThreadSubscriptionNotifierJob.perform_later(post)

    head 200
  end

  def opened
    current_user = User.find_by(email: params["recipient"])
    emailed_post = Post.find_by(message_id: params["message-id"])

    unless current_user.present? && emailed_post.present?
      head 406 and return
    end

    emailed_post.mark_as_visited(current_user)

    head 200
  end

private
  def require_mailgun_origin
    api_key = ENV["MAILGUN_API_KEY"]
    digest = OpenSSL::Digest::SHA256.new
    data = "#{params[:timestamp]}#{params[:token]}"

    unless SecureEquals.secure_equals(params[:signature], OpenSSL::HMAC.hexdigest(digest, api_key, data))
      head 404
    end
  end
end
