class Company

  STANDARD_DECIMAL_PLACES = nil

  INTENSITY_DECIMAL_PLACES = 7

  def self.is_non_numeric_attribute?(attr)
    [ "@company", "@sector", "@country", "@financial_metric" ].include?(attr.to_s)
  end

  def self.is_intensity_attribute?(attr)
    attr.to_s == "@mass_co2e_per_usd_financial_metric"
  end

  attr_accessor :name
  attr_accessor :sector
  attr_accessor :country
  attr_accessor :financial_metric
  attr_accessor :total_financial_metric_usd
  attr_accessor :mass_scope_one_co2e
  attr_accessor :mass_scope_two_co2e
  attr_accessor :mass_co2e_per_usd_financial_metric 
  attr_accessor :energy_scope_one
  attr_accessor :energy_scope_two_total
  attr_accessor :energy_scope_two_electricity

  def initialize(options={})
    options.each do |key,value|
      self.instance_variable_set("@#{key.underscore}".to_sym, value)
    end
    round_attributes
  end

  def name
    @company
  end

  def total_emissions
    @mass_scope_one_co2e.to_f + @mass_scope_two_co2e.to_f
  end

  def round_attributes
    self.instance_variables.each do |ivar|
      next if Company.is_non_numeric_attribute?(ivar) 
      self.instance_variable_set(ivar, round_attribute(ivar))
    end
  end

  def round_attribute(ivar)
    decimal_places = Company.is_intensity_attribute?(ivar) ? INTENSITY_DECIMAL_PLACES : STANDARD_DECIMAL_PLACES
    self.instance_variable_get(ivar).to_f.round(decimal_places)
  end

end