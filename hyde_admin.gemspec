require_relative "lib/hyde_admin/version"

Gem::Specification.new do |s|
  s.name        = 'hyde_admin'
  s.version     = HydeAdmin::VERSION
  s.summary     = "Hyde for Jekyll site"
  s.description = "A Jekyll admin interface"
  s.authors     = ["Sylvain Claudel"]
  s.email       = 'claudel.sylvain@gmail.com'
  
  #all_files       = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.files       = ["lib/hola.rb"]

  s.executables   = all_files.grep(%r!^exe/!) { |f| File.basename(f) }
  s.bindir        = "bin"
  s.require_paths = ["lib"]

  s.homepage    = 'https://rubygems.org/gems/hyde_admin'

  s.metadata      = {
    "source_code_uri" => "https://github.com/rivsc/hyde_admin",
    "bug_tracker_uri" => "https://github.com/rivsc/hyde_admin/issues",
    "changelog_uri"   => "https://github.com/rivsc/hyde_admin/releases",
    "homepage_uri"    => s.homepage,
  }

  s.license       = 'MIT'
end
