var ES; // define global ES (acronym for EBI_Search)  object
if (!ES) { ES = { 'data': [] }; }

(function() { // ES module
  ES.init = function() {
    $.getJSON('https://pgp-uk.github.io/data/json/data.json', function(json) {
      ES.initializeTable(json, 'table');
    });
    $.getJSON('https://pgp-uk.github.io/data/json/out.json', function(json) {
      ES.makePlotIconClickable('table', json);
    });
  };


  ES.initializeTable = function(dataset, tableId) {
    console.log(dataset);
    dataset = ES.addPlotIconToTopTable(dataset);
    var dt = $('#' + tableId).dataTable({
      data: dataset,
      iDisplayLength: 25,
      pagingType: 'full',
      order: [
        [2, "asc"]
      ],
    });
  };

  ES.addPlotIconToTopTable = function(dataset) {
    var button_html = '<button type="button" class="btn btn-default file_btn" aria-label="Download Files" data-toggle="modal" data-target="#file_modal"><span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span></button>';
    for (var i = 0; i < dataset.length; i++) {
      dataset[i].push(button_html);
    }
    return dataset;
  };

  ES.makePlotIconClickable = function(tableId, dataset) {
    $('#' + tableId).on('click', '.file_btn', function() {
      var id_td = $(this).closest('tr').children('td')[0];
      var id = $(id_td).text();
      console.log(id_td);
      console.log(id);
      $('#participant_id_files').text(id);
      var sample_td = $(this).closest('tr').children('td')[1];
      var sample = $(sample_td).text();
      console.log(id_td);
      console.log(id);
      var data = dataset[sample];
      ES.addBamFileHref(data);
      ES.addFastqFilesHref(data);
      ES.addSraFileHref(data);
      ES.addVcfFilesHref(data);
      ES.addIdatFilesHref(data);
    });
  };


  /* Adding ENA links*/

  ES.addBamFileHref = function(data) {
    var ftp_url = 'ftp://' + data.ena[0].submitted_ftp;
    $('#ena_bam_file').attr('href', ftp_url);
  };

  ES.addFastqFilesHref = function(data) {
    var fastq_links = data.ena[0].fastq_ftp.split(';');
    var fastq1ftp_url = 'ftp://' + fastq_links[0];
    $('#ena_fastq_1_file').attr('href', fastq1ftp_url);
    var fastq2ftp_url = 'ftp://' + fastq_links[1];
    $('#ena_fastq_2_file').attr('href', fastq2ftp_url);
  };


  ES.addSraFileHref = function(data) {
    var ftp_url = 'ftp://' + data.ena[0].sra_ftp;
    $('#ena_sra_file').attr('href', ftp_url);
  };

  /* Adding EVA links*/
  ES.addVcfFilesHref = function(data) {
    var vcf_link = data.eva[0].submitted_ftp.split(';');
    var vcf_ftp_url = 'ftp://' + vcf_link[0];
    $('#eva_vcf_file').attr('href', vcf_ftp_url);
    var vcf_tabix_ftp_url = 'ftp://' + vcf_link[1];
    $('#eva_vcf_tabix_file').attr('href', vcf_tabix_ftp_url);
  };

  /* Adding ArrayExpress links*/
  ES.addIdatFilesHref = function(data) {
  for (var i = 0; i < data.arrayexpress.length; i++) {
    var http_url = 'https://www.ebi.ac.uk/arrayexpress/files/' + data.arrayexpress[i].accession+'/' + data.arrayexpress[i].accession + '.raw.1.zip/'+ data.arrayexpress[i].array_data_file;
    var colour = data.arrayexpress[i].array_data_file.split('_')[2];
    var sample_source = data.arrayexpress[i].characteristicsorganism_part;
    if (sample_source == 'blood') {
      if (colour == "Red.idat") {
        $('#array_express_blood_idat_red_file').attr('href', http_url);}
      else{
        $('#array_express_blood_idat_green_file').attr('href', http_url);}
      }
    else{
      if (colour == "Red.idat") {
        $('#array_express_saliva_idat_red_file').attr('href', http_url);}
      else{
        $('#array_express_saliva_idat_green_file').attr('href', http_url);}
      }
    }
  }

}()); // End of ES module
