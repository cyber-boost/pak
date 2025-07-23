# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "pak-sh"
  spec.version = "2.0.1"
  spec.authors = ["PAK.sh Team"]
  spec.email = ["team@pak.sh"]

  spec.summary = "PAK.sh - Universal Package Automation Kit Wrapper"
  spec.description = "Professional wrapper for PAK.sh installation and management via various package managers"
  spec.homepage = "https://pak.sh"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cyber-boost/pak"
  spec.metadata["changelog_uri"] = "https://github.com/cyber-boost/pak/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/cyber-boost/pak/issues"
  spec.metadata["documentation_uri"] = "https://pak.sh/docs"

  spec.files = Dir.glob("{bin,lib}/**/*") + %w[README.md]
  spec.bindir = "bin"
  spec.executables = ["pak-sh"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"

  spec.requirements << "Bash shell"
  spec.requirements << "curl"
  spec.requirements << "git"

  spec.post_install_message = <<~MESSAGE
    🚀 PAK.sh Wrapper has been installed!
    
    To install PAK.sh, run:
      pak-sh install
    
    To check status:
      pak-sh status
    
    To run PAK.sh commands:
      pak-sh run init
      pak-sh run deploy my-package
      pak-sh run web
    
    Documentation: https://pak.sh/docs
    GitHub: https://github.com/cyber-boost/pak
  MESSAGE
end 