# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_customizable_calc_prototype_session',
  :secret      => '56c5f1df9ad7c589daef78e784ca2872d316c6fc644cedc53d74a26742371f09c5460087daceebb2ab4ec1507d65f4a5a2c0285f6848370c26d770206d1c9220'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
