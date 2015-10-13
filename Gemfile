source 'https://rubygems.org'

gem 'rails', '4.1.7'
gem 'pg', :platforms => [:ruby, :mswin]
platforms :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'puma'
  gem 'warbler'
end

gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'devise'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'roo'
gem 'acts_as_list'
gem 'httparty'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'autoprefixer-rails'
gem 'formtastic', '~> 2.1' # Ye Olde Formtastic because formtastic bootstrap doesn't work with formtastic 3 re: https://github.com/mjbellantoni/formtastic-bootstrap/issues/109
gem 'formtastic-bootstrap'
gem 'cocoon'
gem 'dotenv-deployment'
gem 'carrierwave'
gem 'mini_magick'

group :development do
  gem 'spring'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'better_errors', :platforms => :ruby
  gem 'binding_of_caller', :platforms => :ruby
end

group :development, :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'pry-rails'
  gem 'pry-doc'
end

group :test do
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end
