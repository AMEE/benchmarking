# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

module CompanyHelper

  def column_chart(set) # added argument as precursor to abstracting this out to a view helper
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Company')
    data_table.new_column('number', 'CO2e (t)')
    data_table.new_column('number', 'CO2e (t)')
    data_table.new_column('number', 'CO2e (t)')
    data_table.add_rows(set.selected.size)
    set.selected.each_with_index do |selection,index|
      data_table.set_cell(index, 0, selection.name)
      if selection.name == 'My Company'
        data_table.set_cell(index, 1, 0)
        data_table.set_cell(index, 2, selection.total_emissions)
        data_table.set_cell(index, 3, 0)
      elsif selection.name == 'Sector average'
        data_table.set_cell(index, 1, 0)
        data_table.set_cell(index, 2, 0)
        data_table.set_cell(index, 3, selection.total_emissions)
      else
        data_table.set_cell(index, 1, selection.total_emissions)
        data_table.set_cell(index, 2, 0)
        data_table.set_cell(index, 3, 0)
      end
    end

    options = chart_formatting_options
    options[:title] = chart_title(set)

    chart = GoogleVisualr::Interactive::ColumnChart.new(data_table, options)
    chart.add_listener(:select,chart_select_callback)
    return chart
  end

  def chart_title(set)
    if set.normalized? && set.grid_normalized?
      "Scopes 1 and 2 emissions normalized to company #{set.financial_metric.downcase} and grid intensity"
    elsif set.grid_normalized?
      "Scopes 1 and 2 emissions normalized to grid intensity"
    elsif set.normalized?
      "Scopes 1 and 2 emissions normalized to company #{set.financial_metric.downcase}"
    else
      "Disclosed scopes 1 and 2 emissions by company"
    end
  end

  def chart_formatting_options
  	{ :width => 980,
      :height => 300,
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
  end

  def chart_select_callback
  	js  = "\nfunction(){"
  	js << "\n  cell = chart.getSelection()[0];"
  	js << "\n  value = data_table.getFormattedValue(cell.row,0);"
  	js << "\n  scrollToCompany(value.toLowerCase().replace(/ /g,'-'));"
  	js << "\n}"
  	js
  end

end