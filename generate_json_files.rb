require 'typhoeus'
require 'csv'
require 'json'
require 'uri'
require 'pry'

def init(project_accession, array_express_accessions)
  hydra = Typhoeus::Hydra.new
  responses = []
  urls = generate_urls(project_accession, array_express_accessions)
  urls.each { |url| responses << queue_request(hydra, url) }
  hydra.run
  responses
end

def run(out_dir, responses)
  results = analyse_responses(responses)
  write_to_json_file(File.join(out_dir, 'out.json'), results)
  data = create_datatable_json(results)
  write_to_json_file(File.join(out_dir, 'data.json'), data)
end

def generate_urls(project_accession, array_express_accessions)
  create_urls(project_accession, 'ena_eva') +
    create_urls(array_express_accessions, 'arrayexpress')
end

def create_urls(accessions, type)
  urls = []
  accessions.each do |accession|
    if type == 'ena_eva'
      urls << "https://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=#{accession}&result=read_run"
      urls << "https://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=#{accession}&result=analysis"
    elsif type == 'arrayexpress'
      urls << "https://www.ebi.ac.uk/arrayexpress/files/#{accession}/#{accession}.sdrf.txt"
    end
  end
  urls
end

def queue_request(hydra, url)
  request = Typhoeus::Request.new(url, accept_encoding: 'gzip')
  hydra.queue(request)
  request
end

def analyse_responses(responses)
  results = []
  responses.map do |request|
    type = determine_type(request.base_url)
    if request.response.success?
      results += parse_tabular_results(request.response.body, type)
    end
  end
  results += get_genome_report_url
  restructure_results(results)
end

def determine_type(url)
  if url =~ /.sdrf.txt$/
    accession = File.basename(URI.parse(url).to_s, '.sdrf.txt')
    { type: 'arrayexpress', accession: accession }
  elsif url =~ /result=analysis$/
    { type: 'eva' }
  elsif url =~ /result=read_run$/
    { type: 'ena' }
  end
end

def parse_tabular_results(body, type)
  csv = CSV.new(body, headers: true, header_converters: :symbol, col_sep: "\t")
  csv.to_a.map { |row| h = row.to_hash.merge!(type) }
end

# make the sample accession the key of the results hash...
def restructure_results(results)
  r = {}
  results.each do |result|
    if result[:type] == 'arrayexpress'
      pgp_id = normalize_hex_id(result[:characteristicsindividual]).to_sym
    elsif result[:type] == 'ena' || result[:type] == 'eva'
      pgp_id = parse_hex_id(result).to_sym
    elsif result[:type] == 'genome_report'
      pgp_id = normalize_hex_id(result['human_id']).to_sym
    end
    type = result[:type].to_sym
    r[pgp_id] ||= {}
    r[pgp_id][type] ||= []
    r[pgp_id][type] << result.transform_keys(&:to_sym)
  end
  r
end

## Not Used
def get_participant_genome_report_url(sample)
  url = "https://my.personalgenomes.org.uk/profile/#{sample}.json"
  json_string = Typhoeus::Request.new(url).run.body
  data = JSON.parse(json_string)
  genome_report = data['files'].select do |f|
    f['name'] =~ /Genome Report \(Released by PGP-UK on/
  end
  genome_report.empty? ? nil : genome_report[0]['download_url']
end

def get_genome_report_url
  url = 'https://my.personalgenomes.org.uk/public_genetic_data.json'
  json_string = Typhoeus::Request.new(url).run.body
  json = JSON.parse(json_string)
  json['aaData'].select { |e| e['data_type'] == 'Genome Report' }.each do |e|
    e.merge!({ type: 'genome_report' })
  end
end

def write_to_json_file(outfile, data)
  File.open(outfile, 'w') { |io| io.puts data.to_json }
end

def get_sample_id(h)
  return normalize_hex_id(h[:genome_report][0][:human_id]) unless h[:genome_report].nil?
  return parse_hex_id(h[:ena][0]) unless h[:ena].nil?
  return parse_hex_id(h[:eva][0]) unless h[:eva].nil?
  return normalize_hex_id(h[:arrayexpress][0][:characteristicsindividual]) unless h[:arrayexpress].nil?
end

def parse_hex_id(h)
  return normalize_hex_id(h[:sample_alias]) if h[:sample_alias] =~ /uk\S{6}/
  # if not in correct format assume PGP100
  d = SANGER_KEY[ h[:sample_alias] ]
  return nil if h[:sample_title] != d[:sanger_id]
  return normalize_hex_id(d[:pgp_id])
end

def normalize_hex_id(id)
  'uk' + id[2..-1].upcase
end

def create_datatable_json(results)
  data = []
  results.each do |sample, h|
    sample_alias = "<a href='https://my.personalgenomes.org.uk/profile/#{get_sample_id(h)}' target='_blank'>#{get_sample_id(h)}</a>"
    genome_report = h[:genome_report].nil? ? 'Coming Soon!' : "<a href='#{h[:genome_report][0]['download_url']}'><button type='button' class='btn btn-default' aria-label='Genome Report' data-toggle='tooltip' data-trigger='hover' data-placement='bottom' title='Genome Report'><span class='glyphicon glyphicon-file' aria-hidden='true'></span></button></a>"
    experiment_acc = h[:ena].nil? ? 'Coming Soon!' : "<a href='http://www.ebi.ac.uk/ena/data/view/#{h[:ena][0][:experiment_accession]}' target='_blank'>#{h[:ena][0][:experiment_accession]}</a>"
    analysis_acc = h[:eva].nil? ? 'Coming Soon!' : "<a href='http://www.ebi.ac.uk/ena/data/view/#{h[:eva][0][:analysis_accession]}&display=html' target='_blank'>#{h[:eva][0][:analysis_accession]}</a>"
    array_express_acc = h[:arrayexpress].nil? ? 'Coming Soon!' : "<a href='https://www.ebi.ac.uk/arrayexpress/experiments/#{h[:arrayexpress][0][:accession]}/' target='_blank'>#{h[:arrayexpress][0][:accession]}</a>"
    arr = [sample_alias, genome_report, experiment_acc, analysis_acc, array_express_acc]
    puts arr if sample_alias == 'ukAED6EE'
    data << arr
  end
  data
end


### MAIN RUNNING the script

# parse SANGER keys for PGP100
SANGER_KEY = {}
CSV.foreach('sanger_ids_key.csv') do |r|
  SANGER_KEY[r[0]] = {pgp_id: r[1], sanger_id: r[2]}
end

project_accession = ['PRJEB17529', 'PRJEB13150']
array_express_accessions = ['E-MTAB-5377']
out_dir = ARGV[0]

responses = init(project_accession, array_express_accessions)
run(out_dir, responses)
