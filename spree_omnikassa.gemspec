# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_omnikassa'
  s.version     = '0.6.0'
  s.summary     = 'Omnikassa offiste payments for Spree'
  s.description = 'Offsite payments using the Dutch Omnikassa service from Rabobank.'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Bèr Kessels'
  s.email             = 'ber@webschuur.com'
  s.homepage          = 'http://berk.es'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'

  s.add_dependency 'spree', '~> 1.0.6'
end
