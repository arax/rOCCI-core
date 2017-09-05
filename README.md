# rOCCI-core - A Ruby OCCI Framework
[![Travis](https://img.shields.io/travis/the-rocci-project/rOCCI-core.svg?style=flat-square)](http://travis-ci.org/the-rocci-project/rOCCI-core)
[![Gemnasium](https://img.shields.io/gemnasium/the-rocci-project/rOCCI-core.svg?style=flat-square)](https://gemnasium.com/the-rocci-project/rOCCI-core)
[![Gem](https://img.shields.io/gem/v/occi-core.svg?style=flat-square)](https://rubygems.org/gems/occi-core)
[![Code Climate](https://img.shields.io/codeclimate/github/the-rocci-project/rOCCI-core.svg?style=flat-square)](https://codeclimate.com/github/the-rocci-project/rOCCI-core)

## Requirements
### Ruby
* Ruby 2.2.2+ or jRuby 9+ (with JDK7 a JDK8)

## Installation
### Gem
To install the most recent stable version
~~~
gem install occi-core
~~~

To install the most recent beta version
~~~
gem install occi-core --pre
~~~
### Source
To build a bleeding edge version from master
~~~
git clone git://github.com/the-rocci-project/rOCCI-core.git
cd rOCCI-core
gem build occi-core.gemspec
gem install occi-core-*.gem
~~~

## Usage
### Logging
```ruby
require 'occi/infrastructure-ext'
logger = Yell.new STDOUT, name: Object # IO or String
logger.level = :debug                  # see https://github.com/rudionrails/yell
```
### Model
```ruby
model = Occi::InfrastructureExt::Model.new
model.load_core!
model.load_infrastructure!
model.load_infrastructure_ext!

model.valid! # this should never raise an error when using stock model extensions
```
```ruby
model.kinds   # => #<Set ...>
model.mixins  # => #<Set ...>
model.actions # => #<Set ...>
```
```ruby
kind  = model.find_by_identifier! 'http://schemas.ogf.org/occi/infrastructure#compute' # => #<Occi::Core::Kind ...>
mixin = model.find_by_identifier! 'http://schemas.ogf.org/occi/infrastructure#os_tpl' # => #<Occi::Core::Mixin ...>

model.find_dependent mixin # => #<Set ...> of mixins that depend on the given mixin
model.find_related kind    # => #<Set ...> of kinds related to the given kind
```
### Instance Builder
```ruby
# always access the IB instance associated with a model instance
ib = model.instance_builder
ib.get 'http://schemas.ogf.org/occi/infrastructure#compute' # => #<Occi::Infrastructure::Compute ...>
```
### Entity Instance
```ruby
# using `mixin` selected from Model instance
# using `compute` created by InstanceBuilder instance
compute.identify!                   # to generate `occi.core.id`

compute['occi.core.id']             # => #<String ...>
compute['occi.core.title'] = 'Mine' # to assign instance attribute value

compute << mixin                    # add a mixin

compute.valid!                      # to validate
```
### Action Instance
```ruby
# using `action` selected from Model instance
ai = Occi::Core::ActionInstance.new(action: action)

ai['method']          # => #<String ...>
ai['method'] = 'cold' # to assign action instance attribute value

ai.valid!
```
### Collection
```ruby
# using `model`
# using `compute` created by InstanceBuilder instance
# using `compute1` created by InstanceBuilder instance
# using `compute2` created by InstanceBuilder instance
collection = Occi::Core::Collection.new
collection.categories = model.categories

collection << compute
collection << compute1
collection << compute2

collection.valid!
```
```ruby
# using `kind` selected from Model instance
collection.find_by_kind kind     # => #<Set ...> of Occi::Core::Entity or its sub-type
collection.find_by_id!  '12554'  # => #<Occi::Core::Entity ...> or its sub-type
```
### Rendering
```ruby
# using `compute` created by InstanceBuilder instance
compute.valid!    # ALWAYS validate before rendering!

compute.to_text   # => #<String ...>
compute.to_json   # => #<String ...>
```
```ruby
# using `collection` with `collection.categories` set
collection.valid!    # ALWAYS validate before rendering!

collection.to_text   # => #<String ...> with at most one Occi::Core::Entity sub-type
collection.to_json   # => #<String ...>
```
### Parsing
```ruby
model = Occi::InfrastructureExt::Model.new  # empty or partially loaded model instance can be used

mf = File.read File.join('examples', 'rendering', 'model.json')
Occi::Core::Parsers::JsonParser.model(mf, {}, 'application/occi+json', model)

model.valid! # ALWAYS validate before using the model!
```
```ruby
# using `model`
parser = Occi::Core::Parsers::JsonParser.new(model: model, media_type: 'application/occi+json')

cf = File.read File.join('examples', 'rendering', 'instance.json')
entities = parser.entities(cf, {})  # => #<Set ...>

entities.each(&:valid!)             # ALWAYS validate before using parsed instances!
```
### Warehouse
```ruby
module Custom
  class Warehouse < Occi::Core::Warehouse
    class << self
      protected

      def whereami
        # the `warehouse` directory should be located in this directory
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
```
See definitions in [`Occi::Infrastructure::Warehouse`](https://github.com/the-rocci-project/rOCCI-core/tree/master/lib/occi/infrastructure/warehouse) for inspiration.
### Extending Model
If you need to extend the model, use a custom `Warehouse` class to do it. Actions, kinds, and mixins referenced
by identifier in `Custom::Warehouse` definition YAMLs have to be already present in the model instance being extended!
```ruby
model = Occi::InfrastructureExt::Model.new
model.load_core!

Custom::Warehouse.bootstrap! model

model.valid!
```

## Changelog
See `CHANGELOG.md`.

## Code Documentation
[Code Documentation for rOCCI](http://rubydoc.info/github/the-rocci-project/rOCCI-core/)

## Contribute
1. Fork it
2. Create a branch (git checkout -b my_markup)
3. Commit your changes (git commit -am "My changes")
4. Push to the branch (git push origin my_markup)
5. Create an Issue with a link to your branch
