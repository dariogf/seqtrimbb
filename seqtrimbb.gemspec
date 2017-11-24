# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seqtrimbb/version'

Gem::Specification.new do |spec|

  spec.name          = "seqtrimbb"
  spec.version       = Seqtrimbb::VERSION
  spec.authors       = ["Rafael Nuñez", "Dario Guerrero"]
  spec.email         = ["rafnunser@gmail.com", "dariogf@gmail.com"]
  spec.summary       = %q{Sequences preprocessing and cleaning software}
  spec.description   = %q{Seqtrimbb is a plugin based system to preprocess and clean sequences from multiple NGS sequencing platforms}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir.glob(File.join(File.expand_path('..',__FILE__),"**","*")).select{|file_path| !file_path.include?('DB')}
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = '>= 2.3.0'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

end
