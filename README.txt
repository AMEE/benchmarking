== Corporate Emissions Benchmarking Tool 

This application was written as an example of an integration with the AMEE web service for environmental data.

The application represents a tool for discovering and using corporate greenhouse gas emissions and energy consumption data. A number of specific features are available:

# Browse data on companies absolute emissions and energy consumption. 
# Filter by indistrial sector or country.
# Search companies by name.
# Compare and rank (or 'benchmark') companies based on environmental performance.
# Adjust emissions for company size and/or country to ensure fair comparisons.

See: http://benchmarking-demo.ameeapps.com/browse

The data used by the application is information disclosed by over 600 global corporations to the Carbon Disclosure Project in 2010. For more information see http://discover.amee.com/categories/CDP_emissions_and_financial_metrics

Licensed under the BSD 3-Clause license (See LICENSE.txt for details)

Authors: Andrew Berkeley

Copyright: Copyright (c) 2011 AMEE UK Ltd

Homepage: http://github.com/AMEE/benchmarking

== INSTALLATION

Download the codebase and run `bundle install`

=== Defining AMEE API connection details

Next, define AMEE API server and authentication credentials. There are two ways of doing this, both of which follow from the amee gem:

# Set the required server, username and password in /config/amee.yml. There exists a template for this at /config/amee.example.yml.

OR

# Set the required server, username and password as AMEE_SERVER, AMEE_USERNAME and AMEE_PASSWORD environmental variables respectively.

Start the application!

== REQUIREMENTS

 * Ruby 1.8.7
 * bundler
 * AMEE API key

== USAGE

The application is divided into two parts defined by the /browse and /benchmark paths.

=== Browsing company data
The /browse path simply provides a way to browse over 600 global corporations and discover information regarding their annual greenhouse gas emission, energy consumption and emissions intensity (emissions per USD turnover, EBITDA or profit). Use the drop down boxes to filter the companies by industrial sector, country or on the basis of the financial metric which is available for the company.

=== Benchmarking companies
The /benchmark path provides the ability to compare the environmental performance of companies within specific industrial sectors. Adding to, or selecting information from, the form, defines the conditions on which comparisons are made. Use it in the following ways:

# Select a sector to determine which industrial sector is to be analysed.
# Specify values for any of scope 1 emissions, scope 2 emissions, scope 1 energy consumption and scope 2 energy consumption to add a hypothetical company to the comparison.
# Set a financial benchmark value and financial metric type in order to normalize all companies to the same 'size'. In this case, the emissions for each company are scaled accordingly, providing a fairer basis for inter-company comparisons. These normalizations are based on the reported company emissions intensity.
# Set a country in order to normalize each company to the same country. The effect of this selection is to recalculate scope 2 emissions based on the disclosed scope 2 electricity consumption of each company and the appropriate grid electricity emissions factor for the country selected. Grid electricity data is sourced from here: http://discover-test.amee.com/categories/International_electricity_by_DEFRA.
 