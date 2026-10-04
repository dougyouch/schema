# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'open3'
require 'tmpdir'

describe 'bin/schema-json2csv' do
  let(:root) { File.expand_path('../..', __dir__) }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:schema_file) { File.join(tmp_dir, 'person_schema.rb') }
  let(:json_file) { File.join(tmp_dir, 'people.json') }
  let(:csv_file) { File.join(tmp_dir, 'people.csv') }
  let(:people) do
    [
      { id: 1, name: 'Ann', phones: [{ number: '555-0100' }] },
      { id: 2, name: 'Bob', phones: [] }
    ]
  end
  let(:expected_rows) do
    [
      ['id', 'name', 'phones[1].number', 'phones[2].number'],
      ['1', 'Ann', '555-0100', nil],
      ['2', 'Bob', nil, nil]
    ]
  end

  before do
    File.write(schema_file, <<~RUBY)
      class PersonJson2CsvSchema
        include Schema::Model
        schema_include Schema::Associations::HasMany

        attribute :id, :integer
        attribute :name, :string

        has_many :phones, size: 2 do
          attribute :number, :string
        end
      end
    RUBY
    File.write(json_file, JSON.generate(people))
  end

  after { FileUtils.remove_entry(tmp_dir) }

  def run_script(*args, stdin_data: '')
    Open3.capture3(
      RbConfig.ruby, '-I', File.join(root, 'lib'), File.join(root, 'bin/schema-json2csv'), *args,
      stdin_data: stdin_data
    )
  end

  it 'writes headers and rows to stdout' do
    stdout, _stderr, status = run_script('--require', schema_file, '--schema', 'PersonJson2CsvSchema', '--json', json_file)
    expect(status.success?).to eq(true)
    expect(CSV.parse(stdout)).to eq(expected_rows)
  end

  it 'reads json from stdin' do
    stdout, _stderr, status = run_script('--require', schema_file, '--schema', 'PersonJson2CsvSchema', '-',
                                         stdin_data: JSON.generate(people.first))
    expect(status.success?).to eq(true)
    expect(CSV.parse(stdout)).to eq(expected_rows.first(2))
  end

  it 'appends rows to an existing csv file without repeating the headers' do
    2.times do
      _stdout, _stderr, status = run_script('--require', schema_file, '--schema', 'PersonJson2CsvSchema',
                                            '--json', json_file, '--csv', csv_file)
      expect(status.success?).to eq(true)
    end
    expect(CSV.read(csv_file)).to eq(expected_rows + expected_rows.drop(1))
  end

  it 'fails with a message when the json is malformed' do
    File.write(json_file, '{"id": ')
    _stdout, stderr, status = run_script('--require', schema_file, '--schema', 'PersonJson2CsvSchema', '--json', json_file)
    expect(status.success?).to eq(false)
    expect(stderr).to start_with('invalid json:')
    expect(stderr).not_to include('.rb:')
  end

  it 'fails with a message when no schema file is given' do
    _stdout, stderr, status = run_script('--schema', 'PersonJson2CsvSchema', '--json', json_file)
    expect(status.success?).to eq(false)
    expect(stderr).to include('no file required')
  end

  it 'fails with a message when the schema class is unknown' do
    _stdout, stderr, status = run_script('--require', schema_file, '--schema', 'MissingSchema', '--json', json_file)
    expect(status.success?).to eq(false)
    expect(stderr).to include('schema MissingSchema not found')
  end
end
