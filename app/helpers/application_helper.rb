
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

class AMEE::DataAbstraction::CalculationSet

  def all_ongoing_calculations
    ongoing_calculations_by_type.values.inject(AMEE::DataAbstraction::CalculationCollection.new) do |coll,calcs|
      coll += calcs
    end
  end

  def ongoing_calculations_by_type
    hash ={}
    calculations.each do |label,proto|
      hash[label] = AMEE::DataAbstraction::OngoingCalculation.find_by_type(:all, label.to_s, :include => 'terms')
    end
    return hash
  end

  def ongoing_calculations_for(type)
    AMEE::DataAbstraction::OngoingCalculation.find_by_type(:all, type.to_s, :include => 'terms')
  end
end