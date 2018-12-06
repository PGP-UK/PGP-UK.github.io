require 'json'

def generate_urls(hash, keys, hash_is_arry = false)
  keys.map do |k|
    if hash_is_arry
      hash.map { |h| h[k].split(';') }
    else
      hash[k].split(';')
    end
  end.flatten.compact
end

def get_type(type, url)
  if type == 'wgs'
    return 'WGS Fastq' if url.end_with? '.fastq.gz'
    return 'WGS Fastq (_1)' if url.end_with? '_1.fastq.gz'
    return 'WGS Fastq (_2)' if url.end_with? '_2.fastq.gz'
    return 'WGS Bam' if url.end_with? '.bam'
    return 'WGS Bam Index' if url.end_with? '.bam.bai'
    return 'WGS Cram' if url.end_with? '.cram'
  elsif type == 'eva'
    return 'VCF' if url.end_with? '.vcf.gz'
    return 'VCF Tabix Index' if url.end_with? '.vcf.gz.tbi'
    return 'VCF MD5' if url.end_with? '.md5'
  elsif type == 'wgbs'
    return 'WGBS Fastq' if url.end_with? '.fastq.gz'
    return 'WGBS Fastq (_1)' if url.end_with? '_1.fastq.gz'
    return 'WGBS Fastq (_2)' if url.end_with? '_2.fastq.gz'
    return 'WGBS Bam' if url.end_with? '.bam'
    return 'WGBS Bam Index' if url.end_with? '.bam.bai'
  elsif type == 'meth_array'
    return 'Methylation 450k Array Green Saliva IDAT' if url.end_with? 'Grn.idat?saliva'
    return 'Methylation 450k Array Red Saliva IDAT' if url.end_with? 'Red.idat?saliva'
    return 'Methylation 450k Array Green Blood IDAT' if url.end_with? 'Grn.idat?blood'
    return 'Methylation 450k Array Red Blood IDAT' if url.end_with? 'Red.idat?blood'
  elsif type == 'pgp_profile'
    return url.match(/\?(.*)/)[1]
  elsif type == 'proton_rna_seq'
    return 'Transcriptomic - RNAseq BAM' if url.end_with? '.bam?download'
    return 'Transcriptomic - RNAseq BAM index' if url.end_with? '.bam.bai?download'
  elsif type == 'rnaseq'
    return 'Transcriptomic - RNAseq Fastq' if url.end_with? '.fastq.gz'
    return 'Transcriptomic - RNAseq Fastq (_1)' if url.end_with? '_1.fastq.gz'
    return 'Transcriptomic - RNAseq Fastq (_2)' if url.end_with? '_2.fastq.gz'
  elsif type == 'amplicon'
    return 'Transcriptomic - Amplicon Fastq' if url.end_with? '.fastq.gz'
    return 'Transcriptomic - Amplicon Fastq (_1)' if url.end_with? '_1.fastq.gz'
    return 'Transcriptomic - Amplicon Fastq (_2)' if url.end_with? '_2.fastq.gz'
  end
end

def process_links(links, id, type)
  return [] if links.nil? || links.empty?
  links.map { |url| [id.to_s, url.gsub(/\?.*/, ''), get_type(type, url)] }
end

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
  ae_ftp_start = 'ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/experiment/MTAB'
  ae_html_start = 'https://www.ebi.ac.uk/arrayexpress/files'
  links = meth_array.map do |h|
    "#{h[:comment_arrayexpress_ftp_file]}/#{h[:array_data_file]}" \
    "?#{h[:characteristicsorganism_part]}".gsub(ae_ftp_start, ae_html_start)
  end.flatten.compact
  process_links(links, id, 'meth_array')
end

def get_profile_links(id, pgp_profile)
  return if pgp_profile.nil?
  links = pgp_profile[:files].map do |h|
    "#{h[:download_url]}?#{h[:data_type]}"
  end.flatten.compact
  process_links(links, id, 'pgp_profile')
end

def get_proton_rna_seq_links(id, proton_rna_seq)
  return if proton_rna_seq.nil?
  links = generate_urls(proton_rna_seq, %i[fastq_ftp], true)
  process_links(links, id, 'proton_rna_seq')
end

def get_rnaseq_links(id, rnaseq)
  return if rnaseq.nil?
  ae_ftp_start = 'ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/experiment/MTAB'
  ae_html_start = 'https://www.ebi.ac.uk/arrayexpress/files'
  links = rnaseq.map do |h|
    next if h[:comment_derived_arrayexpress_ftp_file].strip.empty?
    next if h[:derived_array_data_file].strip.empty?
    "#{h[:comment_derived_arrayexpress_ftp_file]}/" \
    "#{h[:derived_array_data_file]}?download".gsub(ae_ftp_start, ae_html_start)
  end.flatten.compact
  process_links(links, id, 'rnaseq')
end

def get_amplicon_links(id, amplicon)
  return if amplicon.nil?
  links = generate_urls(amplicon, %i[fastq_ftp], true)
  process_links(links, id, 'amplicon')
end

filename = File.join('www/data/json', 'data.json')

json_content = File.read(filename)
json_data = JSON.parse(json_content, symbolize_names: true)

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

csv_file = File.join('www/data', 'data_file_links.csv')

File.open(csv_file, 'w') { |f| results.each { |r| f.puts r.join(',') } }

json_results = {}
results.each do |r|
  id = r[0]
  json_results[id] ||= []
  json_results[id] << r
end

json_file = File.join('www/data/json', 'data_file_links.json')

File.open(json_file, 'w') { |f| f.puts results.to_json }
