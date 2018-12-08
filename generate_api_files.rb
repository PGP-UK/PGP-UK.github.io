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
  File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(JSON_DATA) }
end

def write_all_participants_as_nd_json
  outfile = API_DIR + 'all_participants'
  File.open(outfile, 'w') do |io|
    JSON_DATA.each do |hex_id, data|
      io.puts({ hex_id => data }.to_json)
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
  outfile = API_DIR + fname
  File.open(outfile, 'w') do |io|
    JSON_DATA.each do |hex_id, d|
      next unless d.key? key
      io.puts({ hex_id => d[key] }.to_json)
    end
  end
end

def write_all_subset(fname, key)
  outfile = API_DIR + "#{fname}.json"
  subset = {}
  JSON_DATA.each do |hex_id, d|
    next unless d.key? key
    subset[hex_id] = d[key]
  end
  File.open(outfile, 'w') { |io| io.puts JSON.pretty_generate(subset) }
end

# RUN ANALYSIS
API_DIR = Pathname.new('www/api/v1/')
json_dir = Pathname.new('www/data/json')

data_content = IO.read(json_dir + 'data.json')
data = JSON.parse(data_content, symbolize_names: true)

download_data_content = IO.read(json_dir + 'data_file_links.json')
download_data = JSON.parse(download_data_content, symbolize_names: true)

JSON_DATA = {}
data.each do |hex_id, d|
  f_data = download_data[hex_id]
  d[:download_urls] = f_data unless f_data.nil?
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
