source 'http://rubygems.org'

group :test do
  gem 'spork'
  gem 'autotest'
  gem 'autotest-rails'
  gem 'autotest-notification'
  gem 'ffaker'

  gem 'spree_auth_devise', :git => "git://github.com/spree/spree_auth_devise"
end

if RUBY_VERSION < "1.9"
  gem "ruby-debug"
else
  gem "ruby-debug19"
end

gemspec
