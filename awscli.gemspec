require File.join([File.dirname(__FILE__),'lib','awscli','version.rb'])

spec = Gem::Specification.new do |s|
  s.name = 'awscli'
  s.version = Awscli::VERSION
  s.author = 'Ashrith'
  s.email = 'ashrith@me.com'
  s.homepage = 'http://github.com/ashrithr/awscli'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Command Line Interface for Amazon Web Services built in Ruby'

  #Files
  #ensure gem is built out of versioned files
  s.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE'] & `git ls-files -z`.split("\0")
  s.test_files = `git ls-files -- {test,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','awscli.rdoc']
  s.rdoc_options << '--title' << 'awscli' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'

  #Dependencies
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('thor', '>=0.17.0')
  s.add_runtime_dependency('fog', '>=1.10.0')
  s.add_runtime_dependency('highline')
end
