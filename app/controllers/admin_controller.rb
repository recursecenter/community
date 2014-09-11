class AdminController < ApplicationController
  before_filter :require_admin
end
