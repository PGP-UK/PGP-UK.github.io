# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'pathname'

def clean_state
  FileUtils.rm_r API_DIR if API_DIR.exist?
  FileUtils.mkdir_p API_DIR
  FileUtils.touch(API_DIR + '.gitkeep')
end

def write_participants_files
  dir = API_DIR + 'participant'
  FileUtils.mkdir_p dir
  JSON_DATA.each do |hex_id, d|
    outfile = dir + hex_id.to_s
    File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(d) }
  end
end

def write_all_participants
  outfile = API_DIR + 'all_participants.json'
  outfile1 = API_DIR + 'all_participants'
  File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(JSON_DATA) }
  File.open(outfile1, 'w') { |io| io.puts JSON.pretty_generate(JSON_DATA) }
end

def write_all_participants_as_nd_json
  outfile = API_DIR + 'all_participants.ndjson'
  File.open(outfile, 'w') do |io|
    JSON_DATA.each do |hex_id, data|
      io.puts({ hex_id: hex_id, data: data }.to_json) unless data.nil?
    end
  end
end

def write_subset_files(dir, key)
  dir = API_DIR + dir
  FileUtils.mkdir_p dir
  JSON_DATA.each do |hex_id, d|
    next unless d.key? key

    outfile = dir + hex_id.to_s
    File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(d[key]) }
  end
end

def write_all_subset_as_ndjson(fname, key)
  outfile = API_DIR + "#{fname}.ndjson"
  File.open(outfile, 'w') do |io|
    JSON_DATA.each do |hex_id, d|
      next unless d.key? key

      io.puts({ hex_id: hex_id, data: d[key] }.to_json) unless d[key].nil?
    end
  end
end

def write_all_subset(fname, key)
  outfile = API_DIR + "#{fname}.json"
  outfile1 = API_DIR + fname
  subset = []
  JSON_DATA.each do |hex_id, d|
    next unless d.key? key

    subset << { hex_id: hex_id, data: d[key] } unless d[key].nil?
  end
  File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(subset) }
  File.open(outfile1, 'w') { |io| io.puts JSON.pretty_generate(subset) }
end

# RUN ANALYSIS
API_DIR = Pathname.new(ARGV[0])

data_dir = Pathname.new(__dir__).parent + 'data'

data_content = IO.read(data_dir + 'data.json')
data = JSON.parse(data_content, symbolize_names: true)

download_data_content = IO.read(data_dir + 'data_file_links.json')
download_data = JSON.parse(download_data_content, symbolize_names: true)

JSON_DATA = {}
data.each do |hex_id, d|
  f_data = download_data[hex_id]
  d[:download_url] = f_data unless f_data.nil?
  JSON_DATA[hex_id] = d
end

clean_state

write_participants_files
write_all_participants_as_nd_json
write_all_participants

# get all possible keys in JSON_DATA
key_types = JSON_DATA.values.map(&:keys).flatten.uniq
key_types.each do |key|
  write_subset_files(key.to_s, key)
  write_all_subset_as_ndjson("all_#{key}", key)
  write_all_subset("all_#{key}", key)
end
