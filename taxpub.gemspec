$:.push File.expand_path("../lib", __FILE__)

require "taxpub/version"

Gem::Specification.new do |s|
  s.name        = 'taxpub'
  s.version     = TaxPub::VERSION
  s.license     = 'MIT'
  s.date        = '2017-07-25'
  s.summary     = "Parse TaxPub XML documents"
  s.description = "Parses TaxPub XML documents and adds methods to pull out conference data, ranked taxa, occurrences, references, etc."
  s.authors     = ["David P. Shorthouse"]
  s.email       = 'davidpshorthouse@gmail.coms'
  s.homepage    = 'https://github.com/dshorthouse/taxpub'

  s.files        = Dir['MIT-LICENSE', 'README.rdoc', 'lib/**/*']
  s.require_path = 'lib'
  s.rdoc_options.concat ['--encoding',  'UTF-8']
  s.add_runtime_dependency "nokogiri", "~> 1.6"
  s.add_development_dependency "rake", "~> 11.1"
  s.add_development_dependency "rspec", "~> 3.4"
  s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "byebug", "~> 9.0"
end