namespace :amee do

  # Performs application setup
  desc 'Fetches all company data. Run as: rake "amee:cache_data"'
  task :cache_data => :environment do |t, args|
    items = BenchmarkController.new.get_company_data
    File.open("#{Rails.root}/config/data.yml",'w') { |file| file.puts YAML.dump items }
  end
end