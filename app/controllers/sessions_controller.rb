class SessionsController < ApplicationController
  def new
    redirect_to client.auth_code.authorize_url(redirect_uri: login_complete_url)
  end

  def complete
    if params.has_key?(:code)
      token = client.auth_code.get_token(params[:code], redirect_uri: login_complete_url)
      user_data = JSON.parse(token.get("/api/v1/people/me").body)
      batch_data = JSON.parse(token.get("/api/v1/batches/#{user_data["batch_id"]}").body)

      user = User.create_or_update(user_data: user_data, batch_data: batch_data)

      login(user)

      redirect_to root_url
    else
      # TODO: Fix me!
      raise params.to_s
    end
  end

  def destroy
    logout
    render text: "Logged out"
  end

private
  def client
    client_id = ENV["HACKER_SCHOOL_CLIENT_ID"]
    client_secret = ENV["HACKER_SCHOOL_CLIENT_SECRET"]
    site = ENV["HACKER_SCHOOL_SITE"] || "https://www.hackerschool.com"

    @client ||= OAuth2::Client.new(client_id, client_secret, site: site)
  end
end
