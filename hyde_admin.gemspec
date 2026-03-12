require_relative "lib/hyde_admin/version"

Gem::Specification.new do |s|
  s.name        = 'hyde_admin'
  s.version     = HydeAdmin::VERSION
  s.summary     = "Hyde for Jekyll site"
  s.description = "A Jekyll admin interface"
  s.authors     = ["Sylvain Claudel"]
  s.email       = 'claudel.sylvain@gmail.com'
  
  all_files     = `git ls-files`.split("\n").reject{ |filepath| filepath.start_with? 'test/' }
  s.files       = all_files

  s.executables   = ['hyde_admin','hyde_admin_config']
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
  s.add_runtime_dependency("roda", "~> 3.48")
  s.add_runtime_dependency("roda-i18n", "~> 0.4")
  s.add_runtime_dependency("roda-http-auth", "~> 0.2")
  s.add_runtime_dependency("escape_utils")
  s.add_runtime_dependency('jekyll')
  s.add_runtime_dependency('image_processing')
  s.add_runtime_dependency('mini_magick')
  s.add_runtime_dependency('rack', "~> 2.2")
  s.add_runtime_dependency('puma')
end
