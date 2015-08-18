source 'https://rubygems.org'

# Specify your gem's dependencies in transflow.gemspec
gemspec

gem 'dry-pipeline', github: 'dryrb/dry-pipeline', branch: 'master'

group :test do
  gem 'transproc'
  gem 'codeclimate-test-reporter', require: false, platforms: :rbx
end

group :tools do
  gem 'byebug', platforms: :mri
end
