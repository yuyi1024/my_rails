source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.3'
# Use mysql2 as the database for Active Record
gem 'mysql2'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
#gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
gem 'capistrano-rails', group: :development

# using ENV
gem "figaro"

gem 'slim'
gem "slim-rails"

# Use jquery as the JavaScript library
gem 'jquery-rails'
# gem "jquery-slick-rails"

gem 'devise'
# gem 'settingslogic'
# gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'cancancan', '~> 2.0'

gem 'aasm', '~> 4.12'

gem "nested_form"

gem 'kaminari'

# gem 'bootstrap', '~> 4.1.3'
gem 'bootstrap-sass', '~> 3.3.6'

#chart
gem "chartkick"

gem 'groupdate'

# Upload files to Google Storage
gem 'carrierwave', '~> 1.0'
# gem 'carrierwave-data-uri'
# gem 'carrierwave-imageoptimizer'
gem "mini_magick", '~> 3.3' 
gem 'rails-assets-jcrop', source: 'https://rails-assets.org'
#gem "papercrop"
gem "fog-aws"
# gem 'google-api-client'
# gem "mime-types"

#paypal
# gem "braintree", "~> 2.88.0"

# ecpay 物流 & 金流
gem 'ecpay_logistics', path: 'vendor/gems/ecpay_logistics-1.0.7'
gem 'ecpay_payment', path: 'vendor/gems/ecpay_payment-1.0.9'

# WYSIWYG
# This is the right gem to use summernote editor in Rails projects.
gem 'summernote-rails'
# gem 'codemirror-rails'
gem "font-awesome-rails"

# To solve the problems on the turbolinks
gem 'jquery-turbolinks'
# gem 'sdoc', '~> 0.4.0', group: :doc

gem "awesome_print"

#testing
gem "faker"
gem "machinist"

group :production do
  gem 'pg'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # find n+1 queries
  # gem 'bullet'
  gem 'rack-mini-profiler'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
