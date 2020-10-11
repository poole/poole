# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "poole-for-jekyll"
  spec.version       = "3.0.0"
  spec.authors       = ["Mark Otto"]
  spec.email         = ["markdotto@gmail.com"]

  spec.summary       = "The Jekyll Butler. A no frills responsive Jekyll blog theme."
  spec.homepage      = "https://getpoole.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README)!i) }

  spec.add_runtime_dependency "jekyll", "~> 4.0"
  spec.add_runtime_dependency "jekyll-feed", '~> 0.15.1'
  spec.add_runtime_dependency "jekyll-gist", '~> 1.5.0'
  spec.add_runtime_dependency "jekyll-paginate", '~> 1.1.0'
  spec.add_runtime_dependency "jekyll-seo-tag", '~> 2.6.1'
  spec.add_runtime_dependency "jekyll-sitemap", '~> 1.4.0'

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 12.0"
end
