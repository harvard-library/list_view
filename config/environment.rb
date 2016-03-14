# Load the Rails application.
require File.expand_path('../application', __FILE__)
#  Tell the mailer where to go
Rails.configuration.action_mailer.default_url_options = {host: ENV['ROOT_URL']}
# Initialize the Rails application.
Rails.application.initialize!
