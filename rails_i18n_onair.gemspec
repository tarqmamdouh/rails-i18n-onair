require_relative "lib/rails_i18n_onair/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_i18n_onair"
  spec.version     = RailsI18nOnair::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/yourusername/rails_i18n_onair"
  spec.summary     = "I18n management gem for Rails monolith applications"
  spec.description = "A comprehensive i18n management solution for Rails monolith applications with translation management, missing key detection, and more."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 2.7.5"

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "rails-i18n", ">= 6.0"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "bootstrap", "~> 5.3"

  spec.add_development_dependency "rspec-rails", "~> 5.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
end
