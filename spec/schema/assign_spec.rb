require 'spec_helper'

describe Schema::Assign do
  let(:schema_class_name) { 'SchemaClass' + SecureRandom.hex(10) }
  let(:schema_class) do
    kls = Class.new do
      include Schema::All

      attribute :id, :integer
      attribute :name, :string
      attribute :cost, :float, default: 0.0

      has_one(:label) do
        attribute :id, :integer
        attribute :name, :string
      end

      has_many(:tags) do
        attribute :id, :integer
        attribute :tag, :string
      end
    end
    Object.const_set(schema_class_name, kls)
    Object.const_get(schema_class_name)
  end
  let(:id) { rand(1_000_000) }
  let(:name) { SecureRandom.hex(10) }
  let(:cost) { (rand(1_000).to_f + rand).round(2) }
  let(:schema_data) do
    {
      id: id,
      name: name,
      cost: cost,
      label: {
        id: 4,
        name: 'test label'
      },
      tags: [
        {
          id: 2,
          tag: 'tag2'
        },
        {
          id: 3,
          tag: 'updated tag3'
        },
        {
          id: nil,
          tag: 'new tag'
        }
      ]
    }
  end
  let(:schema) { schema_class.from_hash(schema_data) }
  let(:model_class) do
    Struct.new(:id, :name, :cost, :user_id, :label) do
      def self.label_class
        @label_class ||= Struct.new(:id, :name)
      end

      def self.tags_class
        @tags_class ||=
          begin
            kls = Class.new(Array) do
              def self.tag_class
                @tag_class ||= Struct.new(:id, :tag)
              end

              def new(*args)
                tag = self.class.tag_class.new(*args)
                append(tag)
                tag
              end
            end
          end
      end

      def build_label
        self.label ||= self.class.label_class.new
      end

      def tags
        @tags ||= self.class.tags_class.new
      end
    end
  end
  let(:model) do
    model_class.new.tap do |model|
      model.tags.new(2, 'tag2')
      model.tags.new(3, 'tag3')
    end
  end
  let(:include_filter) { nil }
  let(:exclude_filter) { nil }

  context '.update_model' do
    subject do
      Schema::Assign.update_model(
        schema: schema,
        model: model,
        include_filter: include_filter,
        exclude_filter: exclude_filter
      )
    end

    before(:each) do
      subject
    end

    it { expect(model.id).to eq(id) }
    it { expect(model.name).to eq(name) }
    it { expect(model.cost).to eq(cost) }
    it { expect(model.user_id).to eq(nil) }

    describe '.update_has_one_association' do
      it { expect(model.label.id).to eq(4) }
      it { expect(model.label.name).to eq('test label') }
    end

    describe '.update_has_many_association' do
      it { expect(model.tags.size).to eq(3) }

      it { expect(model.tags[0].id).to eq(2) }
      it { expect(model.tags[0].tag).to eq('tag2') }

      it { expect(model.tags[1].id).to eq(3) }
      it { expect(model.tags[1].tag).to eq('updated tag3') }

      it { expect(model.tags[2].id).to eq(nil) }
      it { expect(model.tags[2].tag).to eq('new tag') }
    end

    describe '.was_set_filter' do
      let(:include_filter) { Schema::Assign.was_set_filter }

      let(:schema_data) do
        {
          name: name
        }
      end

      let(:model) do
        model_class.new.tap do |model|
          model.id = 891
          model.name = 'Change Me'
          model.cost = 10.0
        end
      end

      it { expect(model.id).to eq(891) }
      it { expect(model.cost).to eq(10.0) }
      it { expect(model.name).to eq(name) }

      describe 'exclude_filter' do
        let(:include_filter) { nil }
        let(:exclude_filter) { Schema::Assign.was_set_filter }


        it { expect(model.id).to eq(nil) }
        it { expect(model.cost).to eq(0.0) } # default
        it { expect(model.name).to eq('Change Me') }
      end
    end
  end
end
