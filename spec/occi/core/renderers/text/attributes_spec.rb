module Occi
  module Core
    module Renderers
      module Text
        describe Attributes do
          subject(:tra) { Attributes.new(nil, nil) }

          let(:attribute_title) { 'occi.core.title' }
          let(:attribute_id) { 'occi.core.id' }

          let(:kind_attributes) do
            {
              attribute_title => instance_double('Occi::Core::AttributeDefinition'),
              attribute_id    => instance_double('Occi::Core::AttributeDefinition')
            }
          end

          let(:attr_def_string) do
            Occi::Core::AttributeDefinition.new
          end

          let(:attr_def_numeric) do
            Occi::Core::AttributeDefinition.new(type: Numeric)
          end

          let(:attr_def_bool) do
            Occi::Core::AttributeDefinition.new(type: Boolean)
          end

          let(:attr_def_ary) do
            Occi::Core::AttributeDefinition.new(type: Array)
          end

          let(:attr_def_hsh) do
            Occi::Core::AttributeDefinition.new(type: Hash)
          end

          let(:attr_def_unkn) do
            Occi::Core::AttributeDefinition.new(type: Object)
          end

          let(:attribute_name) { 'test' }
          let(:attributes) do
            { attribute_name => Occi::Core::Attribute.new }
          end

          let(:kind) { Occi::Core::Kind.new(term: 'kind', schema: 'http://sche.ma/tes#', attributes: kind_attributes) }

          before do
            allow(kind_attributes[attribute_title]).to receive(:default)
            allow(kind_attributes[attribute_id]).to receive(:default)
          end

          describe '#render' do
            context 'as plain with string attribute' do
              let(:value) { 'text' }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_string
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq "X-OCCI-Attribute: #{attribute_name}=\"#{value}\""
              end
            end

            context 'as plain with numeric attribute' do
              let(:value) { 1.0 }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_numeric
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq "X-OCCI-Attribute: #{attribute_name}=#{value}"
              end
            end

            context 'as plain with bool attribute' do
              let(:value) { true }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_bool
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq "X-OCCI-Attribute: #{attribute_name}=#{value}"
              end
            end

            context 'as plain with `nil` attribute' do
              let(:value) { nil }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_string
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq ''
              end
            end

            context 'as plain with array attribute' do
              let(:value) { [] }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_ary
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq "X-OCCI-Attribute: #{attribute_name}=\"#{value}\""
              end
            end

            context 'as plain with hash attribute' do
              let(:value) { {} }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_hsh
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq "X-OCCI-Attribute: #{attribute_name}=\"#{value}\""
              end
            end

            context 'as plain with unknown attribute' do
              let(:value) { Object.new }
              let(:options) { { format: 'text' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_unkn
                tra.object = attributes
                tra.options = options
              end

              it 'raises error' do
                expect { tra.render }.to raise_error(Occi::Core::Errors::RenderingError)
              end
            end

            context 'as plain with string attribute' do
              let(:value) { 'text' }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_string
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => ["#{attribute_name}=\"#{value}\""])
              end
            end

            context 'as plain with numeric attribute' do
              let(:value) { 1.0 }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_numeric
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => ["#{attribute_name}=#{value}"])
              end
            end

            context 'as plain with bool attribute' do
              let(:value) { true }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_bool
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => ["#{attribute_name}=#{value}"])
              end
            end

            context 'as plain with `nil` attribute' do
              let(:value) { nil }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_string
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => [])
              end
            end

            context 'as plain with array attribute' do
              let(:value) { [] }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_ary
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => ["#{attribute_name}=\"#{value}\""])
              end
            end

            context 'as plain with hash attribute' do
              let(:value) { {} }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_hsh
                tra.object = attributes
                tra.options = options
              end

              it 'renders' do
                expect(tra.render).to eq('X-OCCI-Attribute' => ["#{attribute_name}=\"#{value}\""])
              end
            end

            context 'as plain with unknown attribute' do
              let(:value) { Object.new }
              let(:options) { { format: 'headers' } }

              before do
                attributes[attribute_name].value = value
                attributes[attribute_name].attribute_definition = attr_def_unkn
                tra.object = attributes
                tra.options = options
              end

              it 'raises error' do
                expect { tra.render }.to raise_error(Occi::Core::Errors::RenderingError)
              end
            end
          end
        end
      end
    end
  end
end
