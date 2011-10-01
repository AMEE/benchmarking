# Example of how a file format for specifying client data requirements might look
# The intention is that this could be used to configure data mappings for an application
# The application can read this file, and know how, for each kind of calculation can provide
# what the corresponding amee profile item values are for each entry field
# skeleton views for the entry forms can be generated from such a file
# a given form could change in terms of which amee data category backed it, without any change in the visual appearance of the form
describe AMEE::Filters::Filter do
  before :all do
    @c=Calculation.new { # The application has support for an electricity calculation. :electricity is the internal label used to refer to it
      label :electricity
      name "Electricity Consumption"
      path '/business/energy/electricity/grid'
      profile {
        label :energy_used
        # Symbol provided here is used in generating html ids for elements etc
        path 'energyPerTime' #The amee profile item value corresponding to the field
        name "Energy Used" #The display name used on the form
        unit "kWh" #Default unit choice
        type :text_box #Probably not needed, as likely to be the default for profile item value unsets
        validation :float #Probably not needed, as default can be deduced from PIV TYPE in API. Here as illustrative of potential override Can be a symbol for standard validation or regexp
        other_acceptable_units :any #A dropdown should appear allowing choice of energy unit - without this line only kWh allowed
      }
      drill {   
        value 'argentina' #Not to be unset, value pre-given
        label :country  #Name will default to label.humanize if not given
        path 'country' #Some of the fields on the form are drill-downs, but the application doesn't need to display these differently
        #type :autocompleting_text_box #default for a drill with entries is probably a dropdown
      }
      # Alternatively, the drill might be fixed
      #permanent :country {
      #   drill_path 'country'
      #   value 'Argentina'
     
      output { #A marv output value
        label :co2
        path :default #It's not a marv, use the default output
        name "Carbon Dioxide"
      }
    }
    @t=Calculation.new{
      name 'transport'
      label :transport
      path '/transport/car/generic'

      drill {
        path 'fuel'
        label :fuel
        name 'Fuel type'
      }
      drill {
        path 'size'
        label :size
        name 'Vehicle size'
      }
      profile {
        path 'distance'
        label :distance
        name 'Distance Driven'
      }
    }
    @s=CalculationSet.new {
      calculation{
        name 'electricity'
        label :electricity
        path '/business/energy/electricity/grid'
        profile {
          label :usage
          name 'Electricity Used'
          path 'energyPerTime'
        }
        drill {
          label :country
          path 'country'
          value 'Argentina'
        }
        output {
          label :co2
          path :default
        }
      }
    }
  end
  it 'can create an instance' do
    @c.should be_a Calculation
  end
  it 'should know its profiles values' do
    @c.profiles.values.first.path.should eql 'energyPerTime'
  end
  it 'can have values chosen' do
    @c.chosen_profiles.values.should be_empty
    @c.unset_profiles.values.first.path.should eql 'energyPerTime'
    d=@c.clone
    d.choose!(:energy_used=>5)
    d.unset_profiles.values.should be_empty
    d.chosen_profiles.values.first.path.should eql 'energyPerTime'
    d.chosen_profiles.values.first.value.should eql 5
    # Original should be unaffected by the choosing - clone generates a deep copy instance
    @c.chosen_profiles.values.should be_empty
    @c.unset_profiles.values.first.path.should eql 'energyPerTime'
  end
  it 'knows when it is satisfied' do
    d=@c.clone
    d.satisfied?.should be_false
    d.choose!(:energy_used=>5)
    d.satisfied?.should be_true
  end
  it 'knows when its drills are satisfied' do
    t=@t.clone
    t.satisfied?.should be_false
    t.choose!('fuel'=>'diesel')
    t.satisfied?.should be_false
    t2=@t.clone
    t2.choose!('fuel'=>'diesel','size'=>'large')
    t2.satisfied?.should be_false
    t3=@t.clone
    t3.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    t3.satisfied?.should be_true
  end

end
