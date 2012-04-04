module AMEE

  def self.get_single_factor(category_path,drill_string,value_path)
    connection = AMEE::Rails.connection
    uid        = AMEE::Data::DrillDown.get(connection, "#{category_path}/drill?#{drill_string}").data_item_uid
    item       = AMEE::Data::Item.get(connection, "#{category_path}/#{uid}")
    factor     = item.values.find { |value| value[:path] == value_path }[:value]
  end

  module Electricity

    CATEGORY_PATH = "/data/business/energy/electricity/defra/international"

    def self.country_choices
      AMEE::Data::DrillDown.get(AMEE::Rails.connection, "#{CATEGORY_PATH}/drill").choices.unshift("None")
    end

    def self.grid_intensity_factor_by_country(country)
      category_path = CATEGORY_PATH
      drill_string  = "country=#{CGI::escape(country)}&type=electricity+consumption"
      value_path    = "annualMassDirectCO2PerEnergy"
      AMEE.get_single_factor(category_path,drill_string,value_path)
    end

  end
 
end