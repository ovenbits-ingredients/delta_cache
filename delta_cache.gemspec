
# -*- encoding: utf-8 -*-
$:.push('lib')
require "delta_cache/version"

Gem::Specification.new do |s|
  s.name     = "delta_cache"
  s.version  = DeltaCache::VERSION.dup
  s.date     = "2012-02-01"
  s.summary  = "A cache that keeps track of deltas and tombstones for an array of data."
  s.email    = "john.critz@gmail.com"
  s.homepage = ""
  s.authors  = ['John Critz']

  s.description = <<-EOF
A cache that keeps track of deltas and tombstones for an array of data. Deltas and tombstones can be retrieved from the cache using a last-modified timestamp.
EOF

  dependencies = []

  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ["lib"]


  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.8.10"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version

  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
