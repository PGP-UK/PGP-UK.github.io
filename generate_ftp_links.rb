# frozen_string_literal: true

require 'json'
require 'pathname'

def get_wgs_links(id, wgs)
  return if wgs.nil?
  links = generate_urls(wgs, %i[fastq_ftp submitted_ftp], true)
  process_links(links, id, 'wgs')
end

def get_eva_links(id, eva)
  return if eva.nil?
  links = generate_urls(eva, %i[submitted_ftp], true)
  process_links(links, id, 'eva')
end

def get_wgbs_links(id, wgbs)
  return if wgbs.nil?
  links = generate_urls(wgbs, %i[fastq_ftp submitted_ftp], true)
  process_links(links, id, 'wgbs')
end

def get_meth_array_links(id, meth_array)
  return if meth_array.nil?
  ftp = 'ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/experiment/MTAB'
  html = 'https://www.ebi.ac.uk/arrayexpress/files'
  links = meth_array.map do |h|
    "#{h[:comment_arrayexpress_ftp_file]}/#{h[:array_data_file]}" \
    "?#{h[:characteristicsorganism_part]}".gsub(ftp, html)
  end.flatten.compact
  process_links(links, id, 'meth_array')
end

def get_profile_links(id, pgp_profile)
  return if pgp_profile.nil?
  links = pgp_profile[:files].map { |h| "#{h[:download_url]}?#{h[:data_type]}" }
  process_links(links, id, 'pgp_profile')
end

def get_proton_rna_seq_links(id, proton_rna_seq)
  return if proton_rna_seq.nil?
  links = generate_urls(proton_rna_seq, %i[fastq_ftp], true)
  process_links(links, id, 'proton_rna_seq')
end

def get_rnaseq_links(id, rnaseq)
  return if rnaseq.nil?
  ftp = 'ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/experiment/MTAB'
  html = 'https://www.ebi.ac.uk/arrayexpress/files'
  links = rnaseq.map do |h|
    next if h[:comment_derived_arrayexpress_ftp_file].strip.empty?
    next if h[:derived_array_data_file].strip.empty?
    "#{h[:comment_derived_arrayexpress_ftp_file]}/" \
    "#{h[:derived_array_data_file]}?download".gsub(ftp, html)
  end.flatten.compact
  process_links(links, id, 'rnaseq')
end

def get_amplicon_links(id, amplicon)
  return if amplicon.nil?
  links = generate_urls(amplicon, %i[fastq_ftp], true)
  process_links(links, id, 'amplicon')
end

def generate_urls(hash, keys, is_array = false)
  keys.map do |k|
    is_array ? hash.map { |h| h[k].split(';') } : hash[k].split(';')
  end.flatten.compact
end

def process_links(links, id, type)
  return [] if links.nil? || links.empty?
  links.map { |url| [id.to_s, url.gsub(/\?.*/, ''), get_type(type, url)] }
end

def get_type(type, url)
  return get_wgs_type(url) if type == 'wgs'
  return get_eva_type(url) if type == 'eva'
  return get_wgbs_type(url) if type == 'wgbs'
  return get_meth_array_type(url) if type == 'meth_array'
  return get_pgp_profile_type(url) if type == 'pgp_profile'
  return get_proton_rna_seq_type(url) if type == 'proton_rna_seq'
  return get_rnaseq_type(url) if type == 'rnaseq'
  return get_amplicon_type(url) if type == 'amplicon'
end

def get_wgs_type(url)
  return 'WGS Fastq (_1)' if url.end_with? '_1.fastq.gz'
  return 'WGS Fastq (_2)' if url.end_with? '_2.fastq.gz'
  return 'WGS Fastq' if url.end_with? '.fastq.gz'
  return 'WGS Bam' if url.end_with? '.bam'
  return 'WGS Bam Index' if url.end_with? '.bam.bai'
  return 'WGS Cram' if url.end_with? '.cram'
end

def get_eva_type(url)
  return 'VCF' if url.end_with? '.vcf.gz'
  return 'VCF Tabix Index' if url.end_with? '.vcf.gz.tbi'
  return 'VCF MD5' if url.end_with? '.md5'
end

def get_wgbs_type(url)
  return 'WGBS Fastq (_1)' if url.end_with? '_1.fastq.gz'
  return 'WGBS Fastq (_2)' if url.end_with? '_2.fastq.gz'
  return 'WGBS Fastq' if url.end_with? '.fastq.gz'
  return 'WGBS Bam' if url.end_with? '.bam'
  return 'WGBS Bam Index' if url.end_with? '.bam.bai'
end

def get_meth_array_type(url)
  return 'Methylation 450k Array Green Saliva IDAT' if url.end_with? 'Grn.idat?saliva'
  return 'Methylation 450k Array Red Saliva IDAT' if url.end_with? 'Red.idat?saliva'
  return 'Methylation 450k Array Green Blood IDAT' if url.end_with? 'Grn.idat?blood'
  return 'Methylation 450k Array Red Blood IDAT' if url.end_with? 'Red.idat?blood'
end

def get_pgp_profile_type(url)
  url.match(/\?(.*)/)[1]
end

def get_proton_rna_seq_type(url)
  return 'Transcriptomic - RNAseq BAM' if url.end_with? '.bam?download'
  return 'Transcriptomic - RNAseq BAM index' if url.end_with? '.bam.bai?download'
end

def get_rnaseq_type(url)
  return 'Transcriptomic - RNAseq Fastq' if url.end_with? '.fastq.gz'
  return 'Transcriptomic - RNAseq Fastq (_1)' if url.end_with? '_1.fastq.gz'
  return 'Transcriptomic - RNAseq Fastq (_2)' if url.end_with? '_2.fastq.gz'
end

def get_amplicon_type(url)
  return 'Transcriptomic - Amplicon Fastq (_1)' if url.end_with? '_1.fastq.gz'
  return 'Transcriptomic - Amplicon Fastq (_2)' if url.end_with? '_2.fastq.gz'
  return 'Transcriptomic - Amplicon Fastq' if url.end_with? '.fastq.gz'
end

data_dir = Pathname.new 'www/data'
filename = data_dir + 'json' + 'data.json'

json_data = JSON.parse(IO.read(filename), symbolize_names: true)

results = []
json_data.each do |id, data|
  results.push(*get_wgs_links(id, data[:wgs]))
  results.push(*get_eva_links(id, data[:eva]))
  results.push(*get_wgbs_links(id, data[:wgbs]))
  results.push(*get_meth_array_links(id, data[:meth_450k_array]))
  results.push(*get_profile_links(id, data[:profile]))
  results.push(*get_proton_rna_seq_links(id, data[:proton_rna_seq]))
  results.push(*get_rnaseq_links(id, data[:rnaseq]))
  results.push(*get_amplicon_links(id, data[:amplicon]))
end

csv_file = data_dir + 'data_file_links.csv'
File.open(csv_file, 'w') { |f| results.each { |r| f.puts r.join(',') } }

json_results = {}
results.each do |r|
  id = r[0]
  json_results[id] ||= []
  json_results[id] << { type: r[2], download_url: r[1] }
end

json_file = data_dir + 'json' + 'data_file_links.json'
File.open(json_file, 'w') { |f| f.puts json_results.to_json }
