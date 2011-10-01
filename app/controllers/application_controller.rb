# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  protect_from_forgery
  
  include AuthHelper
  include ApplicationHelper
  helper_method :current_user_session, :current_user, :logged_in?, :admin_login_required
  before_filter :initialize_all_company_data
  
  def home
    if logged_in?
      redirect_to summary_path
    else
      redirect_to login_path
    end
  end

  def initialize_all_company_data
    Rails.cache.write('all_company_data',BenchmarkController.new.get_company_data) unless Rails.cache.exist?('all_company_data')
  end

  

end
