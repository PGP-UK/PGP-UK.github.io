var ES; // define global ES (acronym for EBI_Search)  object
if (!ES) { ES = {}; }

(function() { // ES module
  ES.init = function() {
    $.getJSON('https://personalgenomes.org.uk/data/json/data.json', function(json) {
      var datatable = ES.initializeTable(json, 'table');
      $.getJSON('https://personalgenomes.org.uk/data/json/out.json', function(json) {
        ES.makePlotIconClickable(datatable, 'table', json, '.file_btn');
        $('[data-toggle="tooltip"]').tooltip();
      });
      $.getJSON('https://personalgenomes.org.uk/data/json/phenotype.json', function(json) {
        ES.makePlotIconClickable(datatable, 'table', json, '.trait_btn');
        $('[data-toggle="tooltip"]').tooltip();
      });
    });
  };

  ES.initializeTable = function(dataset, tableId) {
    dataset = ES.addPlotIconToTopTable(dataset);
    var dt = $('#' + tableId).DataTable({
      data: dataset,
      responsive: true,
      iDisplayLength: 25,
      pagingType: 'full',
      order: [
        [1, "asc"]
      ],
      bAutoWidth: false,
      columnDefs: [{
        "targets": 5,
        "orderable": false
      },
      {
        "targets": 1,
        "orderable": false
      },
      {
        "width": "104px",
        "targets": 5
    }]
    });
    $('.dataTables_filter').addClass('pull-right')
    return dt;
  };

  ES.addPlotIconToTopTable = function(dataset) {
    var btn_html = '<button type="button" class="btn btn-default trait_btn" aria-label="Trait Data" data-toggle="tooltip" data-trigger="hover" data-placement="bottom" title="Phenotype Data"><span class="glyphicon glyphicon-user" aria-hidden="true"></span></button>&nbsp;&nbsp;<button type="button" class="btn btn-default file_btn" aria-label="Download Files" data-toggle="tooltip" data-trigger="hover" data-placement="bottom" title="Download Files"><span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span></button>';
    for (var i = 0; i < dataset.length; i++) {
      dataset[i].push(btn_html);
    }
    return dataset;
  };

  ES.makePlotIconClickable = function(datatable, tableId, dataset, type) {
    $('#' + tableId).on('click', '.close', function() {
      var $tr = $(this).closest('tr').prev()[0];
      var row = datatable.row( $tr );
      row.child.hide();
      $tr.removeClass('shown');
    });
    $('#' + tableId).on('click', type, function() {
      var $tr  = $(this).closest('tr');
      var id_td = $tr.children('td')[0];
      var id = $(id_td).text();
      var row = datatable.row( $tr );
      if (type == '.trait_btn') {
        ES.openTraitsChildRow(row, $tr, dataset, id);
      } else {
        ES.openFilesChildRow(row, $tr, dataset, id);
      }
    });
  };

  ES.openTraitsChildRow = function(row, tr, dataset, id) {
    if (row.child.isShown() && $(row.child()).find('#traits_'+id).length === 1) {
      // already open
      row.child.hide();
      tr.removeClass('shown');
    } else {
      var data = dataset[id];
      var traits_html = $('#traits_template').clone().attr('id', 'traits_'+id).show();
      traits_html = ES.updateTraitsHtml(data, traits_html);
      row.child( traits_html ).show();
      tr.addClass('shown');
    }
  };

  ES.openFilesChildRow = function(row, tr, dataset, id) {
    if (row.child.isShown() && $(row.child()).find('#files_'+id).length === 1) {
      // already open
      row.child.hide();
      tr.removeClass('shown');
    } else {
      var data = dataset[id];
      var file_html = $('#files_template').clone().attr('id', 'files_'+id).show();
      file_html = ES.addBamFileHref(file_html, data);
      file_html = ES.addFastqFilesHref(file_html, data);
      file_html = ES.addSraFileHref(file_html, data);
      file_html = ES.addVcfFilesHref(file_html, data);
      file_html = ES.addIdatFilesHref(file_html, data);
      row.child( file_html ).show();
      tr.addClass('shown');
    }
  };

  /* Adding ENA links*/
  ES.addBamFileHref = function(file_html, data) {
    var ftp_url = 'ftp://' + data.ena[0].submitted_ftp;
    $(file_html).find('.ena_bam_file').attr('href', ftp_url);
    return file_html;
  };

  ES.addFastqFilesHref = function(file_html, data) {
    var fastq_links = data.ena[0].fastq_ftp.split(';');
    var fastq1ftp_url = 'ftp://' + fastq_links[0];
    $(file_html).find('.ena_fastq_1_file').attr('href', fastq1ftp_url);
    var fastq2ftp_url = 'ftp://' + fastq_links[1];
    $(file_html).find('.ena_fastq_2_file').attr('href', fastq2ftp_url);
    return file_html;
  };

  ES.addSraFileHref = function(file_html, data) {
    var ftp_url = 'ftp://' + data.ena[0].sra_ftp;
    $(file_html).find('.ena_sra_file').attr('href', ftp_url);
    return file_html;
  };

  /* Adding EVA links*/
  ES.addVcfFilesHref = function(file_html, data) {
    var vcf_link = data.eva[0].submitted_ftp.split(';');
    var vcf_ftp_url = 'ftp://' + vcf_link[0];
    $(file_html).find('.eva_vcf_file').attr('href', vcf_ftp_url);
    var vcf_tabix_ftp_url = 'ftp://' + vcf_link[1];
    $(file_html).find('.eva_vcf_tabix_file').attr('href', vcf_tabix_ftp_url);
    return file_html;
  };

  /* Adding ArrayExpress links*/
  ES.addIdatFilesHref = function(file_html, data) {
    if (data.arrayexpress === undefined) {
      $(file_html).find('.array_express_file_data_row').hide();
    } else {
      $(file_html).find('.array_express_file_data_row').show();
      for (var i = 0; i < data.arrayexpress.length; i++) {
        var http_url = 'https://www.ebi.ac.uk/arrayexpress/files/' + data.arrayexpress[i].accession + '/' + data.arrayexpress[i].accession + '.raw.1.zip/' + data.arrayexpress[i].array_data_file;
        var colour = data.arrayexpress[i].array_data_file.split('_')[2];
        var sample_source = data.arrayexpress[i].characteristicsorganism_part;
        if (sample_source == 'blood') {
          if (colour == "Red.idat") {
            $(file_html).find('.array_express_blood_idat_red_file').attr('href', http_url);
          } else {
            $(file_html).find('.array_express_blood_idat_green_file').attr('href', http_url);
          }
        } else {
          if (colour == "Red.idat") {
            $(file_html).find('.array_express_saliva_idat_red_file').attr('href', http_url);
          } else {
            $(file_html).find('.array_express_saliva_idat_green_file').attr('href', http_url);
          }
        }
      }
    }
    return file_html;
  };

  ES.updateTraitsHtml = function (data, traits_html) {
    if (data === undefined) {
      $(traits_html).find('.info_table').remove();
      $(traits_html).find('.survey_sub_text').text('There is no trait data associated with this participant currently.')
    } else {
      $(traits_html).find('.survey_gender').text(data[1]);
      $(traits_html).find('.survey_date_of_birth').text(data[2]);
      $(traits_html).find('.survey_age_at_sample_collection').text(data[3]);
      $(traits_html).find('.survey_current_smoker').text(data[4]);
      $(traits_html).find('.survey_ex_smoker').text(data[5]);
      $(traits_html).find('.survey_blood_type').text(data[6]);
      $(traits_html).find('.survey_handedness').text(data[7]);
      $(traits_html).find('.survey_weight').text(data[8]);
      $(traits_html).find('.survey_height').text(data[9]);
      $(traits_html).find('.survey_hair_colour').text(data[10]);
      $(traits_html).find('.survey_right_eye_colour').text(data[11]);
      $(traits_html).find('.survey_left_eye_colour').text(data[12]);
      $(traits_html).find('.survey_date').text(data[13]);
    }
    return traits_html;
  };

}()); // End of ES module
