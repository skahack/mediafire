# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mediafire/version"

Gem::Specification.new do |s|
  s.name        = "mediafire"
  s.version     = Mediafire::VERSION
  s.authors     = ["SKAhack"]
  s.email       = ["m@skahack.com"]
  s.homepage    = "https://github.com/SKAhack/mediafire"
  s.summary     = %q{Ruby wrapper for the unofficial Mediafire API}
  s.description = %q{A Ruby wrapper for the unofficial Mediafire API}

  s.rubyforge_project = "mediafire"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "multipart-post"
end
