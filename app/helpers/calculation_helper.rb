# To change this template, choose Tools | Templates
# and open the template in the editor.

module CalculationHelper

  def calculation_terms_in_table_order(calculation,include_optional=false,include_outputs=true)
    terms = []
    terms = terms + calculation.metadata.visible
    terms += calculation.drills.visible
    terms += calculation.profiles.compulsory.visible
    terms += calculation.profiles.optional.visible if include_optional
    terms += calculation.outputs.visible if include_outputs
    return terms
  end
    
end
