# frozen_string_literal: true

require 'typhoeus'
require 'csv'
require 'fileutils'
require 'json'
require 'pathname'
require 'uri'

def init(project_accession, arrayexpress_accessions)
  hydra = Typhoeus::Hydra.new
  urls = generate_urls(project_accession, arrayexpress_accessions)
  responses = urls.map { |url| queue_request(hydra, url) }
  hydra.run
  responses
end

def run(out_dir, responses)
  results = analyse_responses(responses)
  write_to_json_file((out_dir + 'data.json'), results)
  data = create_datatable_json(results)
  write_to_json_file((out_dir + 'table.json'), data)
end

def generate_urls(project_accession, arrayexpress_accessions)
  create_urls(project_accession, 'ena_eva') +
    create_urls(arrayexpress_accessions, 'arrayexpress')
end

def create_urls(accessions, type)
  urls = accessions.map do |accn|
    if type == 'ena_eva'
      ena_eva_file_report_url(accn)
    elsif type == 'arrayexpress'
      "https://www.ebi.ac.uk/arrayexpress/files/#{accn}/#{accn}.sdrf.txt"
    end
  end
  urls.flatten
end

def ena_eva_file_report_url(accession)
  url_start = 'https://www.ebi.ac.uk/ena/data/warehouse/filereport'
  ["#{url_start}?accession=#{accession}&result=read_run",
   "#{url_start}?accession=#{accession}&result=analysis"]
end

def queue_request(hydra, url)
  request = Typhoeus::Request.new(url, accept_encoding: 'gzip')
  hydra.queue(request)
  request
end

def analyse_responses(responses)
  results = responses.map do |request|
    next unless request.response.success?
    parse_tabular_results(request.response.body, request.base_url)
  end
  results += query_tapestry
  restructure_results(results.flatten)
end

def parse_tabular_results(body, request_url)
  csv = CSV.new(body, headers: true, header_converters: :symbol, col_sep: "\t")
  csv.to_a.map do |row|
    data_hash = row.to_hash
    type = determine_type(data_hash, request_url)
    data_hash.merge!(type)
  end
end

def determine_type(data_hash, url)
  if url.match?(/.sdrf.txt$/)
    determine_arrayexpress_type(url)
  elsif url.match?(/result=analysis$/)
    { type: 'variant', meta_data_source: url }
  elsif url.match?(/result=read_run$/)
    determine_ena_type(data_hash, url)
  end
end

def determine_arrayexpress_type(url)
  accession = File.basename(URI.parse(url).to_s, '.sdrf.txt')
  if accession == 'E-MTAB-5377'
    { type: 'meth_array', accession: accession, meta_data_source: url }
  elsif accession == 'E-MTAB-6523'
    { type: 'rna_seq', accession: accession, meta_data_source: url }
  end
end

def determine_ena_type(data_hash, url)
  if data_hash[:library_strategy] == 'WGS'
    { type: 'wgs', meta_data_source: url }
  elsif data_hash[:library_strategy] == 'WXS'
    { type: 'wxs', meta_data_source: url }
  elsif data_hash[:library_strategy] == 'Bisulfite-Seq'
    { type: 'wgbs', meta_data_source: url }
  elsif data_hash[:library_strategy] == 'RNA-Seq'
    { type: 'proton_rna_seq', meta_data_source: url }
  elsif data_hash[:library_strategy] == 'AMPLICON'
    { type: 'amplicon_rna_seq', meta_data_source: url }
  end
end

def query_tapestry
  json_string = Typhoeus::Request.new(TAPESTRY_URL).run.body
  json = JSON.parse(json_string, symbolize_names: true)
  genome_report = json[:aaData].select { |e| e[:data_type] == 'Genome Report' }
  genome_report.each { |e| e.merge!(type: 'genome_report') }.sort_by { |e| Date.strptime(e[:published], '%m/%d/%Y') }
  meth_report = json[:aaData].select { |e| e[:data_type] == 'Methylome Report' }
  meth_report.each { |e| e.merge!(type: 'methylome_report') }.sort_by { |e| Date.strptime(e[:published], '%m/%d/%Y') }
  genotype = json[:aaData].select { |e| e[:data_type] == '23andMe' }
  genotype.each { |e| e.merge!(type: 'genotype') }.sort_by { |e| Date.strptime(e[:published], '%m/%d/%Y') }
  [genome_report, genotype, meth_report].flatten
end

# make the sample accession the key of the results hash...
def restructure_results(results)
  r = {}
  results.each do |result|
    pgp_id = get_pgp_id(result)
    type   = result[:type].to_sym
    r[pgp_id] ||= {}
    r[pgp_id][type] ||= []
    r[pgp_id][type] << result
    if r[pgp_id][:pgp_profile].nil?
      r[pgp_id][:pgp_profile] = add_pgp_profile(pgp_id)
    end
    r[pgp_id][:phenotype] = PHENOTYPE_DATA[pgp_id] if r[pgp_id][:phenotype].nil?
  end
  r
end

def add_pgp_profile(pgp_id)
  tapestry_url = "https://my.personalgenomes.org.uk/profile/#{pgp_id}.json"
  json_string = Typhoeus::Request.new(tapestry_url).run.body
  JSON.parse(json_string, symbolize_names: true).merge(type: 'pgp_profile')
end

def get_pgp_id(result)
  if %w[meth_array rna_seq].include? result[:type]
    normalize_hex_id(result[:characteristicsindividual]).to_sym
  elsif %w[variant wgs wxs wgbs amplicon_rna_seq proton_rna_seq].include? result[:type]
    parse_hex_id(result).to_sym
  elsif %w[genome_report genotype methylome_report].include? result[:type]
    normalize_hex_id(result[:pgp_hex_id]).to_sym
  end
end

def get_sample_id(h)
  %i[genome_report genotype methylome_report].each do |type|
    next if h[type].nil?
    return h[type][0][:pgp_hex_id]
  end
  %i[meth_array rna_seq].each do |type|
    next if h[type].nil?
    return h[type][0][:characteristicsindividual]
  end
  %i[variant wgs wgbs wxs amplicon_rna_seq proton_rna_seq].each do |type|
    next if h[type].nil?
    return parse_hex_id(h[type][0])
  end
end

def parse_hex_id(h)
  return parse_hex_id_using_key(h, WGBS_KEY) if h[:type] == 'wgbs'
  if %w[amplicon_rna_seq proton_rna_seq].include? h[:type]
    return parse_hex_id_using_key(h, RNASEQ_KEY)
  end
  # PGP10 use sample_alias; while PGP-donations uses library_name
  %i[sample_alias library_name].each do |key|
    return normalize_hex_id(h[key]) if h[key] =~ /uk\S{6}/
  end
  # if not in correct format assume PGP100
  parse_pgp100_hex_id(h)
end

def parse_hex_id_using_key(h, convert_key)
  h_key = :sample_alias if h[:type] == 'wgbs'
  h_key = :sample_title if %w[amplicon_rna_seq proton_rna_seq].include? h[:type]
  d = h[h_key] =~ /uk\S{6}/ ? h[h_key] : convert_key[h[h_key]]
  normalize_hex_id(d)
end

def parse_pgp100_hex_id(h)
  d = SANGER_KEY[h[:sample_alias]]
  return nil if h[:sample_title] != d[:sanger_id]
  normalize_hex_id(d[:pgp_id])
end

def normalize_hex_id(id)
  'uk' + id[2..-1].upcase.chomp
end

def write_to_json_file(outfile, data)
  File.open(outfile, 'w') { |io| io.puts data.to_json }
end

def create_datatable_json(results)
  results.map do |_, h|
    [
      td1_sample_alias(h),
      td2_reports_btn(h),
      td3_genome_data(h),
      td4_methylome_data(h),
      td5_transcriptome(h),
      td6_buttons
    ]
  end
end

def td1_sample_alias(h)
  sample_alias = get_sample_id(h)
  url = "https://my.personalgenomes.org.uk/profile/#{sample_alias}"
  "<a class='pgp_hex_id' href='#{url}' target='_blank'>#{sample_alias}</a>"
end

def td2_reports_btn(h)
  num = number_of_reports(h)
  return '' if num.nil? || num.zero?
  '<span class=report_btn aria-label="PGP-UK Reports"' \
    ' data-toggle=tooltip data-trigger=hover data-placement=bottom' \
    ' title="PGP-UK Reports">' \
    '<span class="fa-layers fa-fw fa-2x">' \
    '<i class="fal fa-file-alt" data-fa-transform="flip-h"></i>' \
    "<span class='fa-layers-counter fa-lg'>#{num}</span>" \
    '</span></span>'
end

def number_of_reports(h)
  return if h[:methylome_report].nil? && h[:genome_report].nil?
  return h[:genome_report].size if h[:methylome_report].nil?
  return h[:methylome_report].size if h[:genome_report].nil?
  h[:genome_report].size + h[:methylome_report].size
end

def td3_genome_data(h)
  td3_wgs(h) + td3_wxs(h) + td3_vcf(h) + td3_genotype(h)
end

def td3_wgs(h)
  return '' if h[:wgs].nil?
  display = h[:wgs][0][:experiment_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}"
  html = "WGS: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Whole Genome Sequencing')
end

def td3_wxs(h)
  return '' if h[:wxs].nil?
  display = h[:wxs][0][:experiment_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}"
  html = "WXS: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Random Exon Sequencing')
end

def td3_vcf(h)
  return '' if h[:variant].nil?
  display = h[:variant][0][:analysis_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}&display=html"
  html = "VCF: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Variant Call Format')
end

def td3_genotype(h)
  return '' if h[:genotype].nil?
  url = h[:genotype][0][:download_url]
  display = '23andMe Data'
  html = "GT: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Genotype Data (Uploaded by Participant)')
end

def td4_methylome_data(h)
  td4_wgbs(h) + td4_meth_array(h)
end

def td4_wgbs(h)
  return '' if h[:wgbs].nil?
  display = h[:wgbs][0][:experiment_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}"
  html = "WGBS: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Whole Genome Bisulfite Sequencing')
end

def td4_meth_array(h)
  return '' if h[:meth_array].nil?
  display = h[:meth_array][0][:accession]
  url = "https://www.ebi.ac.uk/arrayexpress/experiments/#{display}"
  html = "450k: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Methylation Array Data (450k)')
end

def td5_transcriptome(h)
  td5_amplicon_rna_seq(h) + td5_proton_rna_seq(h) + td5_rna_seq(h)
end

def td5_amplicon_rna_seq(h)
  return '' if h[:amplicon_rna_seq].nil?
  display = h[:amplicon_rna_seq][0][:experiment_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}"
  html = "Amplicon: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Targeted RNA-seq: Amplicon sequencing')
end

def td5_proton_rna_seq(h)
  return '' if h[:proton_rna_seq].nil?
  display = h[:proton_rna_seq][0][:experiment_accession]
  url = "http://www.ebi.ac.uk/ena/data/view/#{display}"
  html = "WTSS: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Targeted RNA-seq: Whole Transcriptome Shotgun Sequencing')
end

def td5_rna_seq(h)
  return '' if h[:rna_seq].nil?
  display = h[:rna_seq][0][:accession]
  url = "https://www.ebi.ac.uk/arrayexpress/experiments/#{display}"
  html = "RNA-SEQ: <a href='#{url}' target='_blank'>#{display}</a><br>"
  title_tooltip(html, 'Whole RNA Sequencing')
end

def td6_buttons
  '<span class="trait_btn" aria-label="Trait Data" data-toggle="tooltip" data-trigger="hover" data-placement="bottom" title="Phenotype Data">' \
    '<i class="fal fa-address-book fa-2x"></i></span>' + '&nbsp;&nbsp;' \
    '<span class="file_btn" aria-label="Download Files" data-toggle="tooltip" data-trigger="hover" data-placement="bottom" title="Download Files">' \
    '<i class="fal fa-download fa-2x"></i></span>'
end

def title_tooltip(display, title, direction = 'left')
  "<span data-toggle=tooltip data-placement=#{direction} title='#{title}'>" \
  "#{display}</span>"
end

def parse_phenotype_csv(input_file)
  r = {}
  File.open(input_file) do |f|
    CSV.foreach(f).each_with_index do |csv_row, idx|
      next if idx.zero? # header line
      next if csv_row.empty?
      pgp_id = normalize_hex_id(csv_row[0]).to_sym
      keys = ['Sex', 'Date of Birth', 'Age at Sample Collection',
              'Current Smoker', 'Ex-Smoker?', 'Blood Type', 'Handedness',
              'Weight', 'Height', 'Hair Colour', 'Right Eye Colour',
              'Left Eye Colour', 'Survey Date']
      zipped_data = keys.zip(csv_row.drop(1))
      r[pgp_id] ||= []
      r[pgp_id] << zipped_data.map { |e| { question: e[0], answer: e[1] } }
    end
  end
  r
end

### MAIN RUNNING the script

# Parse WGBS Keys for PGP10
WGBS_KEY = { 'WGBS_PGP-UK1' => 'uk35C650', 'WGBS_PGP-UK2' => 'uk2E2AAE',
             'WGBS_PGP-UK3' => 'uk2DF242', 'WGBS_PGP-UK4' => 'uk740176',
             'WGBS_PGP-UK5' => 'uk33D02F', 'WGBS_PGP-UK6' => 'uk0C72FF',
             'WGBS_PGP-UK7' => 'uk1097F9', 'WGBS_PGP-UK8' => 'uk174659',
             'WGBS_PGP-UK9' => 'uk85AA3B',
             'WGBS_PGP-UK10' => 'uk481F67' }.freeze

RNASEQ_KEY = { 'Sample_1_PGPUK_B1' => 'uk35C650',
               'Sample_2_PGPUK_B2' => 'uk2E2AAE',
               'Sample_3_PGPUK_B3' => 'uk2DF242',
               'Sample_4_PGPUK_B4' => 'uk740176',
               'Sample_5_PGPUK_B5' => 'uk33D02F',
               'Sample_6_PGPUK_B6' => 'uk0C72FF',
               'Sample_7_PGPUK_B7' => 'uk1097F9',
               'Sample_8_PGPUK_B8' => 'uk174659',
               'Sample_9_PGPUK_B9' => 'uk85AA3B',
               'Sample_10_PGPUK_B10' => 'uk481F67' }.freeze

TAPESTRY_URL = 'https://my.personalgenomes.org.uk/public_genetic_data.json'

data_dir = Pathname.new(__dir__).parent + 'data'
phenotype_csv_file = data_dir + 'phenotype.csv'
sanger_ids_file = data_dir + 'sanger_ids_key.csv'

# parse SANGER keys for PGP100
SANGER_KEY = Hash.new
CSV.foreach(sanger_ids_file) do |r|
  SANGER_KEY[r[0]] = { pgp_id: r[1], sanger_id: r[2] }
end

## Parse Phenotype data
PHENOTYPE_DATA = parse_phenotype_csv(phenotype_csv_file)

project_accession = %w[PRJEB17529 PRJEB13150 PRJEB25139]
arrayexpress_accessions = %w[E-MTAB-5377 E-MTAB-6523]

responses = init(project_accession, arrayexpress_accessions)
run(data_dir, responses)
