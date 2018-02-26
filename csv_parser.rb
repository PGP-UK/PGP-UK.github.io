require 'csv'
require 'json'

def parse_tsv(input_file)
  r = {}
  File.open(input_file) do |f|
    CSV.foreach(f).each_with_index do |csv_row, idx|
      next if idx.zero? # header line
      r[csv_row[0].to_s] = csv_row
    end
  end
  r
end

def write_to_json_file(outfile, data)
  File.open(outfile, 'w') { |io| io.puts data.to_json }
end

input_file = 'phenotype.csv'
out_dir = ARGV[0]
outfile = File.join(out_dir, 'phenotype.json')

data = parse_tsv(input_file)
write_to_json_file(outfile, data)
