# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','awscli','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'awscli'
  s.version = Awscli::VERSION
  s.author = 'Ashrith'
  s.email = 'ashrith@cloudwick.com'
  s.homepage = 'http://ashrithr.github.com/awscli'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Command Line Interface for Amazon Web Services built in Ruby'
# Add your other files here if you make them
  s.files = %w(
bin/awscli
lib/awscli/version.rb
lib/awscli.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','awscli.rdoc']
  s.rdoc_options << '--title' << 'awscli' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'awscli'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('thor')
  s.add_runtime_dependency('fog')
  s.add_runtime_dependency('highline')
end
