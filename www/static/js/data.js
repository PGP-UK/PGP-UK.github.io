var ES; // define global ES (acronym for EBI_Search)  object
if (!ES) { ES = {}; }

(function() { // ES module
  ES.init = function() {
    $.getJSON('/data/json/table.json', function(json) {
      var datatable = ES.initializeTable(json, 'table');
      $.getJSON('/data/json/data.json', function(data_json) {
        ES.makePlotIconClickable(datatable, 'table', data_json, '.file_btn');
        ES.makePlotIconClickable(datatable, 'table', data_json, '.report_btn');
        ES.makePlotIconClickable(datatable, 'table', data_json, '.trait_btn');
      });
    });
  };

  ES.initializeTable = function(dataset, tableId) {
    var dt = $('#' + tableId).DataTable({
      data: dataset,
      responsive: true,
      iDisplayLength: 10,
      pagingType: 'full',
      order: [
        [0, "asc"]
      ],
      bAutoWidth: false,
         columnDefs: [
        {
          targets: 0, sType: 'numeric', render: function (data, type, row, meta) {
            // Sort by the default order in the dataset json with the first column
            if (type === 'sort') {
              return meta.row;
            } else {
              return data;
            }
          }
        },
        {targets: [1,2,3,4,5],orderable: false},
        {width: "104px",target: 5}
      ],
      drawCallback: function() {
        $('[data-toggle="tooltip"]').tooltip();
      }
    });
    $('.dataTables_filter').addClass('pull-right');
    return dt;
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
      var id = $tr.find('.pgp_hex_id').text();
      var row = datatable.row( $tr );
      if (type == '.report_btn') {
        ES.openReportsChildRow(row, $tr, dataset, id);
      } else if (type == '.trait_btn') {
        ES.openTraitsChildRow(row, $tr, dataset, id);
      } else if (type == '.file_btn') {
        ES.openFilesChildRow(row, $tr, dataset, id);
      }
    });
  };

  ES.openReportsChildRow = function(row, tr, dataset, id) {
    if (row.child.isShown() && $(row.child()).find('#reports_'+id).length === 1) {
      // already open
      row.child.hide();
      tr.removeClass('shown');
    } else {
      var data = dataset[id];
      var reports_html = $('#reports_template').clone().attr('id', 'reports_'+id).show();
      reports_html = ES.addGenomeReportHref(reports_html, data);
      reports_html = ES.addMethReportHref(reports_html, data);
      row.child( reports_html ).show();
      tr.addClass('shown');
    }
  };

  ES.addGenomeReportHref = function (file_html, data) {
    if (data.genome_report === undefined) {
      $(file_html).find('.genome_report').hide();
    } else {
      $(file_html).find('.genome_report').show();
      var http_url = data.genome_report[0].download_url;
      $(file_html).find('.genome_report').attr('href', http_url);
    }
    return file_html;
  };

  ES.addMethReportHref = function (file_html, data) {
    if (data.methylome_report === undefined) {
      $(file_html).find('.meth_report').hide();
    } else {
      $(file_html).find('.meth_report').show();
      var http_url = data.methylome_report[0].download_url;
      $(file_html).find('.meth_report').attr('href', http_url);
    }
    return file_html;
  };

  ES.openTraitsChildRow = function(row, tr, dataset, id) {
    if (row.child.isShown() && $(row.child()).find('#traits_'+id).length === 1) {
      // already open
      row.child.hide();
      tr.removeClass('shown');
    } else {
      var data = dataset[id].phenotype[0];
      var traits_html = $('#traits_template').clone().attr('id', 'traits_'+id).show();
      traits_html = ES.updateTraitsHtml(data, traits_html);
      row.child( traits_html ).show();
      tr.addClass('shown');
    }
  };

  ES.updateTraitsHtml = function (data, traits_html) {
    if (data == null) {
      $(traits_html).find('.info_table').remove();
      $(traits_html).find('.survey_sub_text').text('There is no trait data currently associated with this participant.');
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

  ES.openFilesChildRow = function(row, tr, dataset, id) {
    if (row.child.isShown() && $(row.child()).find('#files_'+id).length === 1) {
      // already open
      row.child.hide();
      tr.removeClass('shown');
    } else {
      var data = dataset[id];
      var file_html = $('#files_template').clone().attr('id', 'files_'+id).show();
      file_html = ES.addEnaFilesHref(file_html, data);
      file_html = ES.addVcfFilesHref(file_html, data);
      file_html = ES.addIdatFilesHref(file_html, data);
      file_html = ES.addUserUploadedData(file_html, data);
      row.child( file_html ).show();
      tr.addClass('shown');
    }
  };

  /* Adding links*/
  ES.addEnaFilesHref = function(file_html, data){
    if (data.wgs === undefined) {
      $(file_html).find('.wgs_file_data_row').hide();
      $(file_html).find('.genome_title').hide();
  } else {
      $(file_html).find('.genome_title').show();
      file_html = ES.addBamFileHref(file_html, data);
      file_html = ES.addFastqFilesHref(file_html, data);
      file_html = ES.addSraFileHref(file_html, data);
    }
    return file_html;
  };

  ES.addBamFileHref = function(file_html, data) {
    if (data.wgs[0].submitted_ftp === undefined) {
      $(file_html).find('.  ').hide();
  } else {
      $(file_html).find('.ena_bam_file').show();
      var ftp_url = 'ftp://' + data.wgs[0].submitted_ftp;
      $(file_html).find('.ena_bam_file').attr('href', ftp_url);
    }
    return file_html;
  };

  ES.addFastqFilesHref = function(file_html, data) {
    if (data.wgs[0].fastq_ftp === undefined) {
      $(file_html).find('.ena_fastq_1_file').hide();
      $(file_html).find('.ena_fastq_2_file').hide();
  } else {
      $(file_html).find('.ena_fastq_1_file').show();
      $(file_html).find('.ena_fastq_2_file').show();
      var fastq_links = data.wgs[0].fastq_ftp.split(';');
      var fastq1ftp_url = 'ftp://' + fastq_links[0];
      $(file_html).find('.ena_fastq_1_file').attr('href', fastq1ftp_url);
      var fastq2ftp_url = 'ftp://' + fastq_links[1];
      $(file_html).find('.ena_fastq_2_file').attr('href', fastq2ftp_url);
    }
    return file_html;
  };

  ES.addSraFileHref = function(file_html, data) {
    if (data.wgs[0].sra_ftp === undefined) {
      $(file_html).find('.ena_sra_file').hide();
  } else {
    $(file_html).find('.ena_sra_file').show();
      var ftp_url = 'ftp://' + data.wgs[0].sra_ftp;
      $(file_html).find('.ena_sra_file').attr('href', ftp_url);
    }
    return file_html;
  };

  /* Adding EVA links*/
  ES.addVcfFilesHref = function(file_html, data) {
    if (data.eva === undefined) {
      $(file_html).find('.eva_file_data_row').hide();
  } else {
      var vcf_link = data.eva[0].submitted_ftp.split(';');
      for (var i=0; i<vcf_link.length;i++){
        if (vcf_link[i].split('.').pop()=="tbi"){
          var vcf_tabix_ftp_url = 'ftp://' + vcf_link[i];
          $(file_html).find('.eva_vcf_tabix_file').attr('href', vcf_tabix_ftp_url);
        }else{
        if (vcf_link[i].split('.').pop()=="gz"){
          var vcf_ftp_url = 'ftp://' + vcf_link[i];
          $(file_html).find('.eva_vcf_file').attr('href', vcf_ftp_url);
        }
      }
    }
  }
    return file_html;
  };

  /* Adding ArrayExpress links*/
  ES.addIdatFilesHref = function(file_html, data) {
    if (data.meth_450k_array === undefined) {
      $(file_html).find('.meth_450k_file_data_row').hide();
      $(file_html).find('.methylome_title').hide();
    } else {
      for (var i = 0; i < data.meth_450k_array.length; i++) {
        var http_url = 'https://www.ebi.ac.uk/arrayexpress/files/' + data.meth_450k_array[i].accession + '/' + data.meth_450k_array[i].accession + '.raw.1.zip/' + data.meth_450k_array[i].array_data_file;
        var colour = data.meth_450k_array[i].array_data_file.split('_')[2];
        var sample_source = data.meth_450k_array[i].characteristicsorganism_part;
        if (sample_source == 'blood') {
          if (colour == "Red.idat") {
            $(file_html).find('.meth_450k_blood_idat_red_file').attr('href', http_url);
          } else {
            $(file_html).find('.meth_450k_blood_idat_green_file').attr('href', http_url);
          }
        } else {
          if (colour == "Red.idat") {
            $(file_html).find('.meth_450k_saliva_idat_red_file').attr('href', http_url);
          } else {
            $(file_html).find('.meth_450k_saliva_idat_green_file').attr('href', http_url);
          }
        }
      }
    }
    return file_html;
  };

  ES.addUserUploadedData = function(file_html, data) {
    var user_uploaded_files = data.pgp_profile.files;
    if (user_uploaded_files != undefined) {
      var files = user_uploaded_files.filter(file => ES.filter_user_uploaded_files(file));
      if (files.length) {
        $(file_html).find('#user_uploaded_data').show();
        for (var i = 0; i < files.length; i++) {
          var f_html = '<p class="text-left"><span style="text-transform:capitalize">' + files[i].data_type + '&nbsp;&nbsp;</span>' +
            '<a type="button" href="' + files[i].download_url + '"class="btn btn-default"><i class="fal fa-file-alt"></i>&nbsp;&nbsp;' + files[i].name + '</a></p> <div class=clearfix></div>';
          $(f_html).appendTo($(file_html).find('#user_uploaded_data') );
        }
      }
    }
    return file_html;
  };

  ES.filter_user_uploaded_files = function(file) {
    return file.data_type !== 'Genome Report' && file.data_type !== 'Methylome Report'
  }

}()); // End of ES module
