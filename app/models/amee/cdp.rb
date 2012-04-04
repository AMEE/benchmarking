
module AMEE

  module CDP

    WIKINAME = "CDP_emissions_and_financial_metrics"

    SEARCH_TERMS = [
	    :sector, 
	    :country, 
	    :financial_metric
	  ]

    def self.get_company_data(options={})
      
      CDP.quote_search_terms(options.merge!({ :wikiname => WIKINAME }))

      AMEE::Search::WithinCategory.new(AMEE::Rails.connection, options).map do |item|
        {}.tap do |hash|
          item.data[:values].each { |value| hash[value[:path]] = value[:value] }
        end
      end
    end

    def self.quote_search_terms(options)
      SEARCH_TERMS.each { |attr| options[attr] = "\"#{options[attr]}\"" unless options[attr].blank? }
      options
    end

  end

end