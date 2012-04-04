class CompanySet

  class << self
    attr_reader :all
  end

  @all ||= $company_cache.map do |company|
    Company.new(company)
  end

  def self.attribute_list(attr)
    list = self.all.map { |company| company.send(attr.to_sym) }.uniq
    list.unshift("All")
    list.sort
  end

  def self.country_list
    self.attribute_list(:country)
  end

  def self.sector_list
    self.attribute_list(:sector)
  end

  def self.financial_metric_list
    self.attribute_list(:financial_metric)
  end

  NORMALIZED_ATTRIBUTES = [ 
    'mass_scope_two_co2e', 
    'mass_scope_one_co2e', 
    'energy_scope_one', 
    'energy_scope_two_total', 
    'energy_scope_two_electricity'
  ]
  
  attr_accessor :selected
  attr_reader   :country
  attr_reader   :sector
  attr_reader   :financial_metric
  attr_reader   :financial_measure
  attr_reader   :country_for_grid_normalization

  NORMALIZED_ATTRIBUTES.each do |attr| 
    attr_reader attr.to_sym
  end  

  def initialize(options={})
    if @q = options[:q]
      # do nothing else
    else
      @normalized             = false
      @grid_normalized        = false
      @sector_average         = false
      @country                = options[:country]          == 'All' ? nil : options[:country]
      @sector                 = options[:sector]           == 'All' ? nil : options[:sector]
      @financial_metric       = options[:financial_metric] == 'All' ? nil : options[:financial_metric]
      @financial_measure      = options[:financial_measure].blank?  ? nil : options[:financial_measure]
      @mass_scope_one_co2e    = options[:mass_scope_one_co2e]
      @mass_scope_two_co2e    = options[:mass_scope_two_co2e]
      @energy_scope_one       = options[:energy_scope_one]
      @energy_scope_two_total = options[:energy_scope_two_total]
      @country_for_grid_normalization = options[:country_for_grid_normalization]
    end
    @selected = []
  end

  def search_term?
    @q
  end

  def normalized?
  	@normalized
  end

  def grid_normalized?
  	@grid_normalized
  end

  def sector_average?
  	@sector_average
  end

  def valid_selections?
    @country || @sector || @financial_metric
  end

  def all?
    @selected.size == CompanySet.all.size
  end

  def has_custom_company_data?
    instance_variables.any? do |ivar|
      next unless NORMALIZED_ATTRIBUTES.include? ivar.to_s.gsub("@","")
      !instance_variable_get(ivar).blank?    
    end
  end

  def filter_by_search_term
    @selected = CompanySet.all.find_all do |company|
	    company.name.downcase =~ /\A#{@q.downcase}/
	  end
  end

  def filter
    if valid_selections?
      options = {}
      options[:sector] = @sector unless @sector.blank?
      options[:country] = @country unless @country.blank?
      options[:financialMetric] = @financial_metric unless @financial_metric.blank?
      @selected = AMEE::CDP.get_company_data(options).map! { |company| Company.new(company) }
    else
      @selected = CompanySet.all
    end
    @selected
  end
  
  def normalize!
    @normalized = true
    @selected.each do |selection|
      ratio = @financial_measure.to_f / selection.total_financial_metric_usd.to_f
      NORMALIZED_ATTRIBUTES.each do |attr|
        selection.send((attr+"=").to_sym, (selection.send(attr.to_sym).to_f * ratio))
      end
      selection.round_attributes
    end
  end

  def normalize_grid!
    return if @country_for_grid_normalization == "None"
    factor = AMEE::Electricity.grid_intensity_factor_by_country(@country_for_grid_normalization)
    @selected.each do |selection|
      if selection.energy_scope_two_electricity
        selection.mass_scope_two_co2e = selection.energy_scope_two_electricity.to_f * factor.to_f
      end
      selection.round_attributes
    end
    @grid_normalized = true
  end

  def sort!
    @selected.sort! do |selection, next_selection|
      (selection.total_emissions) <=> (next_selection.total_emissions)
    end
  end

  def append_custom_company_representation   
    options = {}
    options["company"]                            = "My Company"
    options["country"]                            = ""
    options["sector"]                             = @sector
    options["financialMetric"]                    = @financial_metric
    options["mass_scope_one_co2e"]                = @mass_scope_one_co2e
    options["mass_scope_two_co2e"]                = @mass_scope_two_co2e
    options["energy_scope_one"]                   = @energy_scope_one
    options["energy_scope_two_total"]             = @energy_scope_two_total
    options["total_financial_metric_usd"]         = @financial_measure
    options["mass_co2e_per_usd_financial_metric"] = custom_company_metric
    @selected << Company.new(options)
  end

  def append_average_sector_representation    
    options = {}
    options["company"]                       = "Sector average"
    options["country"]                       = ""
    options["sector"]                        = @sector
    options["financialMetric"]               = @financial_metric
    options["massScopeOneCO2e"]              = average(:mass_scope_one_co2e)
    options["massScopeTwoCO2e"]              = average(:mass_scope_two_co2e)
    options["energyScopeOne"]                = average(:energy_scope_one)
    options["energyScopeTwoTotal"]           = average(:energy_scope_two_total)
    options["energyScopeTwoElectricity"]     = average(:energy_scope_two_electricity)
    options["totalFinancialMetricUSD"]       = average(:total_financial_metric_usd)
    options["massCO2ePerUSDFinancialMetric"] = average(:mass_co2e_per_usd_financial_metric)
    @sector_average = true
    @selected << Company.new(options)
  end

  protected

  def custom_company_metric
    unless @mass_scope_one_co2e.blank? ||mass_scope_two_co2e.blank? || @financial_measure.blank?
      (@mass_scope_one_co2e.to_f + @mass_scope_two_co2e.to_f) * 1000 / @financial_measure.to_f
    end
  end

  def average(attr)
    @selected.inject(0.0) do |sum, selection| 
      next unless selection.respond_to? attr.to_sym 
  	  sum + selection.send(attr.to_sym).to_f 
	  end / @selected.size.to_f
  end

end