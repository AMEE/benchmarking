Calculations=
  AMEE::DataAbstraction::CalculationSet.new {
  all_calculations {
    #metadatum {
    #  name 'Reporting period'
    #  label :reporting_period
    #  interface :text_box
    #  note "Provide a reference for the reporting period under consideration"
    #}

    # Correct titles for outputs
    correcting(:co2)   { name "Direct CO2" }
    correcting(:indirect_co2e)  { name "Indirect CO2e" }
    correcting(:life_cycle_co2e)  { name "Life Cycle CO2e" }
    correcting(:methane_co2e)  { name "Direct methane CO2e" }
    correcting(:nitrous_oxide_co2e)  { name "Nitrous oxide CO2e" }
    correcting(:total_direct_co2e)  { name "Direct CO2e" }
  }

  calculation {
    name 'Fuel consumption by energy'
    label :fuel_by_energy
    path '/business/energy/stationaryCombustion/defra/energy'
    terms_from_amee 'default'
    correcting(:comment) {hide!}
  }

  calculation {
    name 'International electricity'
    label :electricity
    path '/business/energy/electricity/defra/international'
    terms_from_amee 'default'
    correcting(:comment) {hide!}
  }

}
