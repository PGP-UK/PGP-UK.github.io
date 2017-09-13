require 'typhoeus'
require 'csv'
require 'json'
require 'uri'

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
      pgp_id = result[:characteristicsindividual].to_sym
    elsif result[:type] == 'ena' || result[:type] == 'eva'
      pgp_id = result[:sample_alias].to_sym
    elsif result[:type] == 'genome_report'
      pgp_id = result['human_id'].to_sym
    end
    type = result[:type].to_sym
    r[pgp_id] ||= {}
    r[pgp_id][type] ||= []
    r[pgp_id][type] << result
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
  return h[:genome_report][0]['human_id'] unless h[:genome_report].nil?
  return h[:ena][0]['sample_alias'] unless h[:ena].nil?
  return h[:eva][0]['sample_alias'] unless h[:eva].nil?
  return h[:arrayexpress][0]['characteristicsindividual'] unless h[:arrayexpress].nil?
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
    data << arr
  end
  data
end

### RUNNING the file
project_accession = ['PRJEB17529']
array_express_accessions = ['E-MTAB-5377']
out_dir = ARGV[0]

responses = init(project_accession, array_express_accessions)
run(out_dir, responses)
