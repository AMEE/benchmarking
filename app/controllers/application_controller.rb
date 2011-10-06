# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  protect_from_forgery
  
  include ApplicationHelper
  before_filter :set_amee_credentials, :initialize_all_company_data

  def initialize_all_company_data
    Rails.cache.write('all_company_data',BenchmarkController.new.get_company_data) unless Rails.cache.exist?('all_company_data')
  end

  def set_amee_credentials
    $AMEE_CONFIG['username'] = ENV['AMEE_USERNAME']
    $AMEE_CONFIG['password'] = ENV['AMEE_PASSWORD']
  end

  

end
