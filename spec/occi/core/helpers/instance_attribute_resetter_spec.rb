module Occi
  module Core
    module Helpers
      describe InstanceAttributeResetter do
        subject { pristine_obj }

        let(:pristine_obj) do
          object = Object.clone.new
          object.extend(InstanceAttributeResetter)
          object
        end

        let(:base_attribute_name) { 'occi.test.attribute' }
        let(:added_attribute_name) { 'occi.test.added' }

        let(:base_attributes) do
          { base_attribute_name => instance_double('Occi::Core::AttributeDefinition') }
        end

        let(:added_attributes) do
          [{
            added_attribute_name => instance_double('Occi::Core::AttributeDefinition')
          }]
        end

        before(:example) do
          allow(subject).to receive(:base_attributes).and_return(base_attributes)
          allow(subject).to receive(:added_attributes).and_return(added_attributes)
        end

        describe '#reset_attributes!'
        describe '#reset_attributes'
        describe '#remove_undef_attributes'

        describe '#attribute_names' do
          context 'with attributes' do
            it 'returns attribute names in list' do
              expect(subject.attribute_names).to include(base_attribute_name)
              expect(subject.attribute_names).to include(added_attribute_name)
              expect(subject.attribute_names).to be_kind_of Array
            end
          end

          context 'without attributes' do
            before(:example) do
              allow(subject).to receive(:base_attributes).and_return({})
              allow(subject).to receive(:added_attributes).and_return([{}])
            end

            it 'returns empty list' do
              expect(subject.attribute_names).to be_empty
              expect(subject.attribute_names).to be_kind_of Array
            end
          end

          context 'with nil attribute names' do
            before(:example) do
              allow(subject).to receive(:base_attributes).and_return(
                { nil => instance_double('Occi::Core::AttributeDefinition') }
              )
              allow(subject).to receive(:added_attributes).and_return(
                [{ nil => instance_double('Occi::Core::AttributeDefinition') }]
              )
            end

            it 'returns empty list' do
              expect(subject.attribute_names).to be_empty
              expect(subject.attribute_names).to be_kind_of Array
            end
          end
        end

        describe '#reset_base_attributes'
        describe '#reset_added_attributes'
        describe '#reset_base_attributes!'
        describe '#reset_added_attributes!'

        describe '#reset_attribute' do
          context 'when attribute exists' do
            let(:attributes) do
              { base_attribute_name => instance_double('Occi::Core::Attribute') }
            end

            before(:example) do
              allow(subject).to receive(:attributes).and_return(attributes)
              allow(attributes[base_attribute_name]).to receive(:value).and_return('nope')
              allow(attributes[base_attribute_name]).to receive(:attribute_definition)
              allow(base_attributes[base_attribute_name]).to receive(:default).and_return('test')
            end

            context 'when `force` is used' do
              it 'overwrites previous value' do
                allow(attributes[base_attribute_name]).to receive(:attribute_definition=)
                expect(subject.attributes[base_attribute_name]).to receive(:default!)
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], true)
                end.not_to raise_error
              end

              it 'changes definition' do
                expect(attributes[base_attribute_name]).to receive(:attribute_definition=)
                expect(subject.attributes[base_attribute_name]).to receive(:default!)
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], true)
                end.not_to raise_error
              end
            end

            context 'when `force` is not used' do
              it 'keeps previous value' do
                allow(attributes[base_attribute_name]).to receive(:attribute_definition=)
                expect(subject.attributes[base_attribute_name]).to receive(:default)
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], false)
                end.not_to raise_error
              end

              it 'changes definition' do
                expect(attributes[base_attribute_name]).to receive(:attribute_definition=)
                expect(subject.attributes[base_attribute_name]).to receive(:default)
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], false)
                end.not_to raise_error
              end
            end
          end

          context 'when attribute does not exist' do
            let(:attributes) { {} }

            before(:example) do
              allow(subject).to receive(:attributes).and_return(attributes)
              allow(base_attributes[base_attribute_name]).to receive(:default).and_return('test')
            end

            context 'when `force` is used' do
              it 'creates attribute' do
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], true)
                end.not_to raise_error
                expect(subject.attributes[base_attribute_name]).to be_kind_of Occi::Core::Attribute
              end

              it 'sets default attribute value' do
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], true)
                end.not_to raise_error
                expect(subject.attributes[base_attribute_name].value).to eq 'test'
              end
            end

            context 'when `force` is not used' do
              it 'creates attribute' do
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], false)
                end.not_to raise_error
                expect(subject.attributes[base_attribute_name]).to be_kind_of Occi::Core::Attribute
              end

              it 'sets default attribute value' do
                expect do
                  subject.reset_attribute(base_attribute_name, base_attributes[base_attribute_name], false)
                end.not_to raise_error
                expect(subject.attributes[base_attribute_name].value).to eq 'test'
              end
            end
          end
        end
      end
    end
  end
end
