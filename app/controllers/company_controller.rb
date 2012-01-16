require 'pp'
require "rexml/document"
require 'ihsh'

class CompanyController < ApplicationController

  before_filter :companies

  def benchmark
    generate
  end

  def browse
    generate
  end

  def update
    generate
  end

  def generate
    @normalized = false
    @grid_normalized = false
    @sector_average = false
    initialize_lists
    if params[:q]
      @items = @companies.find_all {|company| company['company']['value'].downcase =~ /\A#{params[:q].downcase}/}
      # Don't display chart if no items or all items
      column_chart unless @items.empty? || @items.size == @companies.size
    else
      initialize_settings(params)
      initialize_data
      unless session[:settings][:financial_measure].blank?
        @normalized = true
        normalize_data if @items.size > 0
      end
      if @items.size > 0 && !session[:settings][:sector].blank?
        append_average_sector_representation
      end
      if !session[:settings][:massScopeOneCO2e].blank? || !session[:settings][:massScopeTwoCO2e].blank? ||
           !session[:settings][:energyScopeOne].blank? || !session[:settings][:energyScopeTwoTotal].blank?
        append_custom_company_representation  if @items.size > 0
      end
      if !session[:settings][:country_for_grid_normalization].blank?
        @grid_normalized = true
        normalize_grid
      end
      if valid_selections? && @items.size > 0
        sort_data
        column_chart
      end
    end
  end

  def normalize_data
    @items.each do |item|
      ratio = session[:settings][:financial_measure].to_f / item['totalFinancialMetricUSD']['value'].to_f
      normalized_attributes.each do |attr|
        item[attr]['value'] = (item[attr]['value'].to_f * ratio).round(2)
      end
    end
  end

  def normalize_grid
    @grid_intensity_factor = get_grid_intensity_factor
    @items.each do |item|
      unless item['energyScopeTwoElectricity'].blank?
        item['massScopeTwoCO2e']['value'] = (item['energyScopeTwoElectricity']['value'].to_f * @grid_intensity_factor.to_f).round(2)
      end
    end
  end

  def sort_data
    @items.sort! do |item, next_item|
      (total_emissions(item)) <=> (total_emissions(next_item))
    end
  end

  def append_custom_company_representation
    hash = {}
    hash["company"] = { "value" => "My Company" }
    hash["massScopeTwoCO2e"] = { "unit" => "t", "value" => (session[:settings][:massScopeTwoCO2e].blank? ? nil : session[:settings][:massScopeTwoCO2e].to_f.round) }
    hash["country"] = { "value" => ""}
    hash["financialMetric"] = { "value" => session[:settings][:financialMetric] }
    hash["massScopeOneCO2e"] = { "unit" => "t", "value" => (session[:settings][:massScopeOneCO2e].blank? ? nil : session[:settings][:massScopeOneCO2e].to_f.round) }
    hash["energyScopeTwoTotal"] = { "unit" => "MWh", "value" => session[:settings][:energyScopeTwoTotal].blank? ? nil : session[:settings][:energyScopeTwoTotal].to_f.round }
    hash["energyScopeOne"] = { "unit" => "MWh", "value" => session[:settings][:energyScopeOne].blank? ? nil : session[:settings][:energyScopeOne].to_f.round }
    hash["totalFinancialMetricUSD"] = { "value" => session[:settings][:financial_measure].to_f.round(2) }
    if !session[:settings][:massScopeOneCO2e].blank? && !session[:settings][:massScopeTwoCO2e].blank? && !session[:settings][:financial_measure].blank?
      hash["massCO2ePerUSDFinancialMetric"] = { "unit" => "kg", "value"=> ((session[:settings][:massScopeOneCO2e].to_f+session[:settings][:massScopeTwoCO2e].to_f)*1000/session[:settings][:financial_measure].to_f).round(7) }
    else
      hash["massCO2ePerUSDFinancialMetric"] = ""
    end
    hash["sector"] = {"value"=> session[:settings][:sector] }
    @items << hash
  end

  def append_average_sector_representation
    @sector_average = true
    hash = {}
    hash["company"] = { "value" => "Sector average" }
    hash["massScopeTwoCO2e"] = { "unit" => "t", "value" => (@items.inject(0.0) { |sum, item| sum + item['massScopeTwoCO2e']['value'].to_f }/@items.size.to_f).round }
    hash["country"] = { "value" => ""}
    hash["financialMetric"] = { "value" => session[:settings][:financialMetric] }
    hash["massScopeOneCO2e"] = { "unit" => "t", "value" => (@items.inject(0.0) { |sum, item| sum + item['massScopeOneCO2e']['value'].to_f }/@items.size.to_f).round }
    hash["energyScopeTwoTotal"] = { "unit" => "MWh", "value" => (@items.inject(0.0) { |sum, item| sum + item['energyScopeTwoTotal']['value'].to_f }/@items.size.to_f).round }
    hash["energyScopeTwoElectricity"] = { "unit" => "MWh", "value" => (@items.inject(0.0) { |sum, item| sum + item['energyScopeTwoElectricity']['value'].to_f }/@items.size.to_f).round }
    hash["energyScopeOne"] = { "unit" => "MWh", "value" => (@items.inject(0.0) { |sum, item| sum + item['energyScopeOne']['value'].to_f }/@items.size.to_f).round }
    hash["totalFinancialMetricUSD"] = { "value" => (@items.inject(0.0) { |sum, item| sum + item['totalFinancialMetricUSD']['value'].to_f }/@items.size.to_f).round(2) }
    hash["massCO2ePerUSDFinancialMetric"] = { "unit" => "kg", "value"=> "" }
    hash["sector"] = {"value"=> session[:settings][:sector] }
    @items << hash
  end

  def initialize_settings(params)
    session[:settings] ||= {}
    session[:settings][:country] = params['country'] == 'All' ? nil : params['country']
    session[:settings][:sector]  = params['sector'] == 'All' ? nil : params['sector']
    session[:settings][:financialMetric] = params['financialMetric'] == 'All' ? nil : params['financialMetric']
    session[:settings][:financial_measure]  = params['financial_measure']
    session[:settings][:massScopeOneCO2e]  = params['scope1_emissions']
    session[:settings][:massScopeTwoCO2e]  = params['scope2_emissions']
    session[:settings][:energyScopeOne]  = params['scope1_energy']
    session[:settings][:energyScopeTwoTotal] = params['scope2_energy']
    session[:settings][:country_for_grid_normalization] = params['country_for_grid_normalization'] == 'None' ? nil : params['country_for_grid_normalization']
  end

  def initialize_data
    if valid_selections?
      @items = get_company_data(options_for_company_data_get)
    else
      @items = @companies
    end
  end
  
  def companies
    @companies ||= YAML.load_file("#{Rails.root}/config/data.yml")
  end

  def options_for_company_data_get
    hash = {}
    hash[:sector] = session[:settings][:sector]
    hash[:country] = session[:settings][:country]
    hash[:financialMetric] = session[:settings][:financialMetric]
    return hash
  end

  def valid_selections?
    session[:settings][:country] || session[:settings][:sector] || session[:settings][:financialMetric]
  end

  def get_company_data(options={})
    items = []
    @result_start = 0
    @truncated_list = true
    while @truncated_list == true do
      options.merge!({'resultStart' => @result_start, 'resultLimit' => 100})
      xml = get_xml(options)
      items += parse_list(xml)
      @result_start += 100
    end
    return items
  end

  def get_xml(options)
    http_options = auth_credentials.merge(:accept => "application/xml")
    url = "https://platform-api-#{ENV['AMEE_SERVER']}/3/categories/CDP_emissions_and_financial_metrics/items;full#{querify(options) if options}"
    xml = ::Ihsh.get(url, http_options)
    return xml
  end

  def parse_list(xml)
    doc = REXML::Document.new(xml).root.elements["Items"]
    @truncated_list = doc.attributes["truncated"] == 'true' ? true : false
    items = []
    doc.elements.each("Item") do |item|
      items << parse_item(item)
    end
    return items
  end

  def parse_item(item)
    hash = {}
    values = item.elements['Values']
    values.elements.each("Value") do |elem|
      next if IGNORED_ATTRIBUTES.include?(elem.elements["Path"].text)
      data = {}
      data['value'] = elem.elements["Value"].text unless elem.elements["Value"].nil?
      data['unit'] = elem.elements["Unit"].text unless elem.elements["Unit"].nil?
      hash[elem.elements["Path"].text] = data
    end
    return hash
  end

  def querify(hash)
    string = "?" + hash.map do |key,value|
      next if value.nil? || value.blank?
      value = "%22#{CGI::escape(value)}%22" if value.is_a? String
      "#{key.to_s}=#{value}"
    end.compact.join("&")
    return string
  end

  def total_emissions(item)
    item['massScopeOneCO2e']['value'].to_f + item['massScopeTwoCO2e']['value'].to_f
  end

  def column_chart
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Company')
    data_table.new_column('number', 'CO2e (t)')
    data_table.new_column('number', 'CO2e (t)')
    data_table.new_column('number', 'CO2e (t)')
    data_table.add_rows(@items.size)
    @items.each_with_index do |item,index|
      data_table.set_cell(index, 0, item['company']['value'])
      if item['company']['value'] == 'My Company'
        data_table.set_cell(index, 1, 0)
        data_table.set_cell(index, 2, total_emissions(item))
        data_table.set_cell(index, 3, 0)
      elsif item['company']['value'] == 'Sector average'
        data_table.set_cell(index, 1, 0)
        data_table.set_cell(index, 2, 0)
        data_table.set_cell(index, 3, total_emissions(item))
      else
        data_table.set_cell(index, 1, total_emissions(item))
        data_table.set_cell(index, 2, 0)
        data_table.set_cell(index, 3, 0)
      end
    end


    if @normalized && @grid_normalized
      title = "Scopes 1 and 2 emissions normalized to company #{session[:settings][:financialMetric].downcase} and grid intensity"
    elsif @grid_normalized
      title = "Scopes 1 and 2 emissions normalized to grid intensity"
    elsif @normalized
      title = "Scopes 1 and 2 emissions normalized to company #{session[:settings][:financialMetric].downcase}"
    else
      title = "Disclosed scopes 1 and 2 emissions by company"
    end

    opts = { :width => 980,
             :height => 300,
             :title => title,
             :titlePosition => 'out',
             :titleTextStyle => { :color => '#525252'},
             :colors =>  ['#79afff','#33CC66','#5e5e5e'],
             :chartArea => { :width => 800, :left => 150, :top => 70 },
             :vAxis => { :title => 'CO2e (tonnes)',
                         :titleTextStyle => {:color => '#525252'}},
             :hAxis => { :textPosition => 'in',
                         :slantedText => 'true',
                         :slantedTextAngle => 90,
                         :maxAlternation => 4 },
             :legend => 'none',
             :backgroundColor => { :stroke => '#79afff'},
             :enableInteractivity => 'true',
             :isStacked => 'true'
           }
    @chart = GoogleVisualr::Interactive::ColumnChart.new(data_table, opts)
    chart_select_callback = "function(){cell = chart.getSelection()[0]; value = data_table.getFormattedValue(cell.row,0);  scrollToCompany(value.toLowerCase().replace(/ /g,'-'));}"
    @chart.add_listener(:select,chart_select_callback)
    return @chart
  end

  def country_drill_down_list
    AMEE::Data::DrillDown.get(connection, "/data/business/energy/electricity/defra/international/drill").choices.unshift("None")
  end

  def get_grid_intensity_factor
    uid = AMEE::Data::DrillDown.get(connection,
      "/data/business/energy/electricity/defra/international/drill?country=#{CGI::escape(session[:settings][:country_for_grid_normalization])}&type=electricity+consumption").data_item_uid
    item = AMEE::Data::Item.get(connection,
       "/data/business/energy/electricity/defra/international/#{uid}")
     factor = item.values.find { |value| value[:path] == 'annualMassDirectCO2PerEnergy'}[:value]
  end

  def initialize_lists
    @sector_list = SECTOR_LIST
    @country_list = COUNTRY_LIST
    @financial_metric_list = FINANCIAL_METRIC_LIST
    @country_list_for_grid_normalization = country_drill_down_list
  end

  def normalized_attributes
    [ 'massScopeTwoCO2e', 'massScopeOneCO2e', 'energyScopeTwoTotal', 'energyScopeOne', 'energyScopeTwoElectricity' ]
  end

  def connection
    AMEE::Connection.new(ENV['AMEE_SERVER'], ENV['AMEE_USERNAME'], ENV['AMEE_PASSWORD'])
  end

  def auth_credentials
    { :username => ENV['AMEE_USERNAME'],
      :password => ENV['AMEE_PASSWORD'] }
  end

  IGNORED_ATTRIBUTES = [ "energyScopeTwoCooling",
                         "reportingPeriodStart",
                         "energyScopeTwoHeat",
                         "reportingPeriodEnd",
                         "energyScopeTwoSteam" ]

  COUNTRY_LIST = [ "All",
                   "Argentina",
                   "Australia",
                   "Austria",
                   "Belgium",
                   "Bermuda",
                   "Brazil",
                   "Canada",
                   "Chile",
                   "China",
                   "Denmark",
                   "Finland",
                   "France",
                   "Germany",
                   "Greece",
                   "Hong Kong",
                   "India",
                   "Ireland",
                   "Italy",
                   "Japan",
                   "Luxembourg",
                   "Mexico",
                   "Netherlands",
                   "New Zealand",
                   "Norway",
                   "Portugal",
                   "South Africa",
                   "South Korea",
                   "Spain",
                   "Sweden",
                   "Switzerland",
                   "Taiwan",
                   "Turkey",
                   "United Kingdom",
                   "USA" ]

  SECTOR_LIST = [ "All",
                  "Advertising",
                  "Aerospace & Defense",
                  "Agricultural Products",
                  "Air Freight & Logistics",
                  "Airlines",
                  "Airport Services",
                  "Aluminum",
                  "Apparel Retail",
                  "Apparel, Accessories & Luxury Goods",
                  "Application Software",
                  "Asset Management & Custody Banks",
                  "Auto Parts & Equipment",
                  "Automobile Manufacturers",
                  "Biotechnology",
                  "Brewers",
                  "Broadcasting",
                  "Building Products",
                  "Cable & Satellite",
                  "Casinos & Gaming",
                  "Catalog Retail",
                  "Commercial Printing",
                  "Commodity Chemicals",
                  "Communications Equipment",
                  "Computer Hardware",
                  "Computer Storage & Peripherals",
                  "Construction & Engineering",
                  "Construction & Farm Machinery & Heavy Trucks",
                  "Construction Materials",
                  "Consumer Electronics",
                  "Consumer Finance",
                  "Data Processing & Outsourced Services",
                  "Department Stores",
                  "Distillers & Vintners",
                  "Distributors",
                  "Diversified Banks",
                  "Diversified Capital Markets",
                  "Diversified Chemicals",
                  "Diversified Financial Services",
                  "Diversified Metals & Mining",
                  "Diversified REIT's",
                  "Diversified Support Services",
                  "Drug Retail",
                  "Electric Utilities",
                  "Electrical Components & Equipment",
                  "Electronic Components",
                  "Electronic Equipment & Instruments",
                  "Electronic Manufacturing Services",
                  "Environmental & Facilities Services",
                  "Fertilizers & Agricultural Chemicals",
                  "Food Distributors",
                  "Food Retail",
                  "Footwear",
                  "Gas Utilities",
                  "General Merchandise Stores",
                  "Gold",
                  "Health Care Distributors",
                  "Health Care Equipment",
                  "Health Care Facilities",
                  "Heavy Electrical Equipment",
                  "Highways & Railtracks",
                  "Home Furnishings",
                  "Home Improvement Retail",
                  "Homebuilding",
                  "Hotels, Resorts & Cruise Lines",
                  "Household Appliances",
                  "Household Products",
                  "Human Resource & Employment Services",
                  "Hypermarkets & Super Centers",
                  "Independent Power Producers & Energy Traders",
                  "Industrial Conglomerates",
                  "Industrial Gases",
                  "Industrial Machinery",
                  "Industrial REIT's",
                  "Insurance Brokers",
                  "Integrated Oil & Gas",
                  "Integrated Telecommunication Services",
                  "Internet Software & Services",
                  "Investment Banking & Brokerage",
                  "IT Consulting & Other Services",
                  "Life & Health Insurance",
                  "Life Sciences Tools & Services",
                  "Managed Health Care",
                  "Marine",
                  "Marine Ports & Services",
                  "Metal & Glass Containers",
                  "Multi-line Insurance",
                  "Multi-Sector Holdings",
                  "Multi-Utilities",
                  "NoIndustrySectorDefinedByCRM",
                  "Office Electronics",
                  "Office REIT's",
                  "Oil & Gas Drilling",
                  "Oil & Gas Equipment & Services",
                  "Oil & Gas Exploration & Production",
                  "Oil & Gas Storage & Transportation",
                  "Other Diversified Financial Services",
                  "Packaged Foods & Meats",
                  "Paper Packaging",
                  "Paper Products",
                  "Personal Products",
                  "Pharmaceuticals",
                  "Photographic Products",
                  "Precious Metals & Minerals",
                  "Property & Casualty Insurance",
                  "Publishing",
                  "Railroads",
                  "Real Estate Operating Companies",
                  "Real Estate Services",
                  "Regional Banks",
                  "Research & Consulting Services",
                  "Restaurants",
                  "Retail REIT's",
                  "Security & Alarm Services",
                  "Semiconductor Equipment",
                  "Semiconductors",
                  "Soft Drinks",
                  "Specialized Consumer Services",
                  "Specialized Finance",
                  "Specialized REIT's",
                  "Specialty Chemicals",
                  "Specialty Stores",
                  "Steel",
                  "Systems Software",
                  "Technology Distributors",
                  "Textiles",
                  "Tobacco",
                  "Trading Companies & Distributors",
                  "Trucking",
                  "Water Utilities",
                  "Wireless Telecommunication Services" ]

  FINANCIAL_METRIC_LIST = [ "All",
                            "EBITDA",
                            "Profit",
                            "Revenue",
                            "Turnover" ]
  
end