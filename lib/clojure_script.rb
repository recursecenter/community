module ClojureScript
  def self.env
    ENV["CLJS_ENV"] || ENV["CLIENT_ENV"] || ENV["RAILS_ENV"] || "development"
  end
end
