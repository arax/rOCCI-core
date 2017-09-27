module Occi
  module Core
    describe Resource do
      subject(:res) { resource }

      let(:attribute_title) { 'occi.core.title' }
      let(:attribute_id) { 'occi.core.id' }
      let(:attribute_summary) { 'occi.core.summary' }
      let(:attribute_source) { 'occi.core.source' }
      let(:attribute_target) { 'occi.core.target' }
      let(:attributes) do
        {
          attribute_title   => instance_double('Occi::Core::AttributeDefinition'),
          attribute_id      => instance_double('Occi::Core::AttributeDefinition'),
          attribute_summary => instance_double('Occi::Core::AttributeDefinition')
        }
      end
      let(:link_attributes) do
        {
          attribute_title   => instance_double('Occi::Core::AttributeDefinition'),
          attribute_id      => instance_double('Occi::Core::AttributeDefinition'),
          attribute_source  => instance_double('Occi::Core::AttributeDefinition'),
          attribute_target  => instance_double('Occi::Core::AttributeDefinition')
        }
      end

      let(:kind) { instance_double('Occi::Core::Kind') }
      let(:link_kind) { instance_double('Occi::Core::Kind') }

      let(:resource) { Resource.new(kind: kind, title: 'My Resource', id: SecureRandom.uuid) }

      let(:link) { Link.new(kind: link_kind, title: 'My Link', id: SecureRandom.uuid) }
      let(:link1) { Link.new(kind: link_kind, title: 'My Link 1', id: SecureRandom.uuid) }

      before do
        allow(link_kind).to receive(:attributes).and_return(link_attributes)
        allow(link_kind).to receive(:location).and_return(URI.parse('/kind/'))
        link_attributes.each_key { |attrib| allow(link_attributes[attrib]).to receive(:default) }

        allow(kind).to receive(:attributes).and_return(attributes)
        allow(kind).to receive(:location).and_return(URI.parse('/kind/'))
        attributes.each_key { |attrib| allow(attributes[attrib]).to receive(:default) }
      end

      RES_ATTRS = [:summary].freeze

      RES_ATTRS.each do |attr|
        it "has #{attr} accessor" do
          is_expected.to have_attr_accessor attr.to_sym
        end
      end

      it 'has attributes value accessor' do
        expect(res).to be_kind_of(Helpers::InstanceAttributesAccessor)
        expect(res).to respond_to(:[])
        expect(res).to respond_to(:[]=)
        expect(res).to respond_to(:attribute?)
      end

      it 'has logger' do
        expect(res).to respond_to(:logger)
        expect(res.class).to respond_to(:logger)
      end

      it 'is renderable' do
        expect(res).to be_kind_of(Helpers::Renderable)
        expect(res).to respond_to(:render)
      end

      describe '#summary' do
        it 'redirects to `occi.core.summary`' do
          expect(res).to receive(:[]).with('occi.core.summary')
          expect { res.summary }.not_to raise_error
        end
      end

      describe '#summary=' do
        it 'redirects to `occi.core.summary`' do
          expect(res).to receive(:[]=).with('occi.core.summary', 'text')
          expect { res.summary = 'text' }.not_to raise_error
        end
      end

      describe '#links=' do
        let(:link) { instance_double('Occi::Core::Link') }
        let(:empty_links) { Set.new }
        let(:links) { Set.new([link]) }

        context 'with links' do
          before do
            expect(link).to receive(:source=).with(res.location)
            expect(link).to receive(:source_kind=).with(res.kind)
          end

          it 'assigns links with changed `source`' do
            expect { res.links = links }.not_to raise_error
            expect(res.links).to eq links
          end
        end

        context 'with empty links' do
          it 'does not do anything' do
            expect { res.links = empty_links }.not_to raise_error
          end
        end

        context 'without links' do
          it 'raises error' do
            expect { res.links = nil }.to raise_error(Occi::Core::Errors::InstanceValidationError)
          end
        end
      end

      describe '#<<' do
        context 'with link' do
          it 'calls `add_link`' do
            expect(res).to receive(:add_link).with(link)
            expect { res << link }.not_to raise_error
          end
        end

        context 'with unknown object' do
          it 'raises error' do
            expect { res << Object.new }.to raise_error(ArgumentError)
          end
        end
      end

      describe '#remove' do
        context 'with link' do
          it 'calls `remove_link`' do
            expect(res).to receive(:remove_link).with(link)
            expect { res.remove(link) }.not_to raise_error
          end
        end

        context 'with unknown object' do
          it 'raises error' do
            expect { res.remove(Object.new) }.to raise_error(ArgumentError)
          end
        end
      end

      describe '#add_link' do
        context 'with link' do
          context 'already assigned' do
            let(:links) { Set.new([link]) }

            before do
              expect { res.links = links }.not_to raise_error
            end

            it 'does not do anything' do
              expect(res.links).to include(link)
              expect(res.links.count).to eq 1
              expect { res.add_link(link) }.not_to raise_error
              expect(res.links).to include(link)
              expect(res.links.count).to eq 1
            end
          end

          context 'not already assigned' do
            it 'adds link' do
              expect(res.links).not_to include(link)
              expect { res.add_link(link) }.not_to raise_error
              expect(res.links).to include(link)
            end
          end
        end

        context 'without link' do
          it 'raises error' do
            expect { res.add_link(nil) }.to raise_error(Occi::Core::Errors::MandatoryArgumentError)
          end
        end
      end

      describe '#remove_link' do
        context 'with link' do
          context 'already assigned' do
            let(:links) { Set.new([link]) }

            before do
              expect { res.links = links }.not_to raise_error
            end

            it 'removes link' do
              expect(res.links).to include(link)
              expect { res.remove_link(link) }.not_to raise_error
              expect(res.links).not_to include(link)
            end
          end

          context 'not already assigned' do
            it 'does not do anything' do
              expect(res.links).not_to include(link)
              expect { res.remove_link(link) }.not_to raise_error
              expect(res.links).not_to include(link)
            end
          end
        end

        context 'without link' do
          it 'raises error' do
            expect { res.remove_link(nil) }.to raise_error(Occi::Core::Errors::MandatoryArgumentError)
          end
        end
      end

      describe '#valid!' do
        context 'with missing required attributes' do
          before do
            expect(attributes.values).to all(receive(:valid!))
            res.instance_variable_set(:@links, nil)
          end

          it 'raises error' do
            expect { res.valid! }.to raise_error(Occi::Core::Errors::InstanceValidationError)
          end
        end

        context 'with all required attributes' do
          before do
            expect(attributes.values).to all(receive(:valid!))
          end

          it 'passes without error' do
            expect { res.valid! }.not_to raise_error
          end
        end
      end

      describe '#links_by_kind' do
        let(:link) { instance_double('Occi::Core::Link') }
        let(:links) { Set.new([link]) }

        before do
          res.instance_variable_set(:@links, links)
        end

        context 'with matches' do
          before do
            expect(link).to receive(:kind).and_return(link_kind)
          end

          it 'returns link(s)' do
            expect(res.links_by_kind(link_kind)).to include(link)
          end
        end

        context 'with no matches' do
          before do
            expect(link).to receive(:kind).and_return(kind)
          end

          it 'returns empty' do
            expect(res.links_by_kind(link_kind)).to be_empty
          end
        end
      end

      describe '#links_by_kind_identifier' do
        let(:link) { instance_double('Occi::Core::Link') }
        let(:links) { Set.new([link]) }

        before do
          res.instance_variable_set(:@links, links)
        end

        context 'with matches' do
          before do
            expect(link).to receive(:kind_identifier).and_return('bla')
          end

          it 'returns link(s)' do
            expect(res.links_by_kind_identifier('bla')).to include(link)
          end
        end

        context 'with no matches' do
          before do
            expect(link).to receive(:kind_identifier).and_return('meh')
          end

          it 'returns empty' do
            expect(res.links_by_kind_identifier('bla')).to be_empty
          end
        end
      end

      describe '#links_by_klass' do
        let(:link) { instance_double('Occi::Core::Link') }
        let(:links) { Set.new([link]) }

        before do
          res.instance_variable_set(:@links, links)
        end

        context 'with matches' do
          before do
            expect(link).to receive(:is_a?).and_return(true)
          end

          it 'returns link(s)' do
            expect(res.links_by_klass('bla')).to include(link)
          end
        end

        context 'with no matches' do
          before do
            expect(link).to receive(:is_a?).and_return(false)
          end

          it 'returns empty' do
            expect(res.links_by_klass('bla')).to be_empty
          end
        end
      end
    end
  end
end
