class CompanyController < ApplicationController

  before_filter :generate

  def benchmark; end

  def browse; end

  def update; end

  def generate
    
    @company_set = CompanySet.new(params)

    if @company_set.search_term?

      @company_set.filter_by_search_term
      @chart = true unless @company_set.selected.empty? || @company_set.all?

    else

      @company_set.filter

      if @company_set.selected.size > 0

        @company_set.normalize! if @company_set.financial_measure
        
        @company_set.append_average_sector_representation if @company_set.sector

        @company_set.append_custom_company_representation if @company_set.has_custom_company_data?

        @company_set.normalize_grid! if @company_set.country_for_grid_normalization

      end

      if @company_set.valid_selections? && @company_set.selected.size > 0 && !@company_set.all?

        @company_set.sort! 
        @chart = true
       
      end
    end
  end

end