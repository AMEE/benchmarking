require 'pp'
require "rexml/document"

class BenchmarkController < ApplicationController

  before_filter :login_required

  def show
    generate
  end

  def update
    generate
  end

  def generate
    @normalized = false
    initialize_lists
    initialize_settings(params)
    initialize_data
    unless session[:settings][:financial_measure].blank?
      @normalized = true
      normalize_data if @items.size > 0
      append_average_sector_representation if @items.size > 0
      if !session[:settings][:massScopeOneCO2e].blank? || !session[:settings][:massScopeTwoCO2e].blank? ||
          !session[:settings][:energyScopeOne].blank? || !session[:settings][:energyScopeTwoTotal].blank?
        append_custom_company_representation  if @items.size > 0
      end
      sort_data
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

  def sort_data
    @items.sort! do |item, next_item|
      (item['massScopeOneCO2e']['value'].to_f + item['massScopeTwoCO2e']['value'].to_f) <=> (next_item['massScopeOneCO2e']['value'].to_f + next_item['massScopeTwoCO2e']['value'].to_f)
    end
  end

  def append_custom_company_representation
    hash = {}
    hash["company"] = { "value" => "My Company" }
    hash["massScopeTwoCO2e"] = { "unit" => "t", "value" => session[:settings][:massScopeTwoCO2e] }
    hash["country"] = { "value" => ""}
    hash["financialMetric"] = { "value" => session[:settings][:financialMetric] }
    hash["massScopeOneCO2e"] = { "unit" => "t", "value" => session[:settings][:massScopeOneCO2e].to_f.round(2) }
    hash["energyScopeTwoTotal"] = { "unit" => "MWh", "value" => session[:settings][:energyScopeTwoTotal].to_f.round(2) }
    hash["energyScopeOne"] = { "unit" => "MWh", "value" => session[:settings][:energyScopeOne].to_f.round(2) }
    hash["totalFinancialMetricUSD"] = { "value" => session[:settings][:financial_measure].to_f.round(2) }
    hash["massCO2ePerUSDFinancialMetric"] = { "unit" => "kg", "value"=> ((session[:settings][:massScopeOneCO2e].to_f+session[:settings][:massScopeTwoCO2e].to_f)/session[:settings][:financial_measure].to_f).round(2) }
    hash["sector"] = {"value"=> session[:settings][:sector] }
    @items << hash
  end

  def append_average_sector_representation
    hash = {}
    hash["company"] = { "value" => "Sector average" }
    hash["massScopeTwoCO2e"] = { "unit" => "t", "value" => (@items.inject(0.0) { |sum, item| sum + item['massScopeTwoCO2e']['value'].to_f }/@items.size.to_f).round(2) }
    hash["country"] = { "value" => ""}
    hash["financialMetric"] = { "value" => session[:settings][:financialMetric] }
    hash["massScopeOneCO2e"] = { "unit" => "t", "value" => (@items.inject(0.0) { |sum, item| sum + item['massScopeOneCO2e']['value'].to_f }/@items.size.to_f).round(2) }
    hash["energyScopeTwoTotal"] = { "unit" => "MWh", "value" => (@items.inject(0.0) { |sum, item| sum + item['energyScopeTwoTotal']['value'].to_f }/@items.size.to_f).round(2) }
    hash["energyScopeOne"] = { "unit" => "MWh", "value" => (@items.inject(0.0) { |sum, item| sum + item['energyScopeOne']['value'].to_f }/@items.size.to_f).round(2) }
    hash["totalFinancialMetricUSD"] = { "value" => (@items.inject(0.0) { |sum, item| sum + item['totalFinancialMetricUSD']['value'].to_f }/@items.size.to_f).round(2) }
    hash["massCO2ePerUSDFinancialMetric"] = { "unit" => "kg", "value"=> "" }
    hash["sector"] = {"value"=> session[:settings][:sector] }
    @items << hash
  end

  def update
    initialize_lists
    initialize_settings(params)
    initialize_data
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
    session[:settings][:energyScopeTwoTotal]  = params['scope2_energy']
  end

  def initialize_data
    if valid_selections?
      @items = get_company_data(options_for_company_data_get)
    else
      @items = Rails.cache.read('all_company_data')
    end
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
    url = "https://platform-api-science.amee.com/3/categories/CDP_emissions_and_financial_metrics/items;full#{querify(options) if options}"
    xml = Ihsh.get(url, http_options)
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

  def initialize_lists
    @sector_list = SECTOR_LIST
    @country_list = COUNTRY_LIST
    @financial_metric_list = FINANCIAL_METRIC_LIST
  end

  def normalized_attributes
    [ 'massScopeTwoCO2e', 'massScopeOneCO2e', 'energyScopeTwoTotal', 'energyScopeOne' ]
  end

  def auth_credentials
    { :username => $AMEE_CONFIG['username'],
      :password => $AMEE_CONFIG['password'] }
  end

  IGNORED_ATTRIBUTES = [ "energyScopeTwoCooling",
                         "energyScopeTwoElectricity",
                         "reportingPeriodStart",
                         "energyScopeTwoHeat",
                         "reportingPeriodEnd",
                         "energyScopeTwoSteam" ]

  COUNTRY_LIST = [ "Argentina",
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

  SECTOR_LIST = [ "Advertising",
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

  FINANCIAL_METRIC_LIST = [ "EBITDA",
                            "Profit",
                            "Revenue",
                            "Turnover" ]
  
end
