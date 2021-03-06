require 'occi/infrastructure'

Yell.new '/dev/null', name: Object

model = Occi::Infrastructure::Model.new
model.load_core!
model.load_infrastructure!

model.valid!

parser = Occi::Core::Parsers::TextParser.new(model: model, media_type: 'text/plain')
cf = File.read File.join(File.dirname(__FILE__), 'rendering', 'instance.txt')

compute = parser.entities(cf, {}).first
compute.valid!
