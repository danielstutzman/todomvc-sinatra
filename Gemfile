source 'https://rubygems.org'

gem 'sinatra', require: 'sinatra/base'
gem 'dotenv'

gem 'activerecord', '~> 4.2', '>= 4.2.5'
gem 'pg'
gem 'sinatra-activerecord'
gem 'activerecord-postgresql-adapter'

gem 'bundler'
gem 'rake'

group :development do
  gem 'tugboat' # call Digital Ocean API from command-line
  gem 'zabbixapi' # call Zabbix API from Ruby
  gem 'rake-compiler' # so I can build pg gem binary
  gem 'hoe' # so I can build pg gem binary
end

group :test do
  gem 'rspec'
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'pry'
  gem 'yarjuf' # JUnit RSpec formatter for Jenkins
  gem 'database_cleaner'
  gem 'rack-test', require: 'rack/test'
end

group :production do
  gem 'unicorn'
end

gem 'thin'
