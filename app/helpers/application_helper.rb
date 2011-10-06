
module ApplicationHelper

  def admin_login_required
    unless current_user.admin
      store_location
      flash[:notice] = "You must be an admin user in to access this page"
      redirect_to user_path(current_user)
      return false
    end
  end
  
end