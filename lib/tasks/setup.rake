namespace :setup do

  # Performs application setup
  desc 'Sets up initial application data - only run once. Run as: rake "setup:data[<email>, <password>]"'
  task :data, :email, :password, :needs => :environment do |t, args|
    # Get commandline options
    user_opts = {
      :email => args[:email],
      :password => args[:password],
      :password_confirmation => args[:password],
      :admin => true
    }

    # Create user
    User.create!(user_opts)
  end
end