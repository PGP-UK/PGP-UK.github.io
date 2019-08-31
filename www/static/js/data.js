var ES; // define global ES (acronym for EBI_Search)  object
if (!ES) {
  ES = {};
}

(function() {
  // ES module
  ES.API_VERSION = 'v1.1';
  ES.init = function() {
    $.getJSON('/data/json/table.json', function(json) {
      ES.table_json = json;
      var datatable = ES.initializeTable(json, 'data_table');
      $.getJSON('/api/' + ES.API_VERSION + '/all_participants.json', function(data_json) {
        ES.data_json = data_json;
        ES.makePlotIconClickable(datatable, 'data_table', data_json, '.file_btn');
        ES.makePlotIconClickable(datatable, 'data_table', data_json, '.report_btn');
        ES.makePlotIconClickable(datatable, 'data_table', data_json, '.trait_btn');
      });
    });
  };


  ES.initializeTable = function(dataset, tableId) {
    var dt = $('#' + tableId).DataTable({
      data: dataset,
      responsive: true,
      iDisplayLength: 10,
      pagingType: 'full',
      order: [[0, 'asc']],
      search: ES.checkForDefaultSearch(),
      bAutoWidth: false,
      columnDefs: [
        {
          targets: 0,
          sType: 'numeric',
          render: function(data, type, row, meta) {
            // Sort by the default order in the dataset json with the first column
            if (type === 'sort') {
              return meta.row;
            } else {
              return data;
            }
          }
        },
        { targets: [1, 2, 3, 4, 5], orderable: false },
        { target: 5, width: '104px' }
      ],
      drawCallback: function() {
        $('[data-toggle="tooltip"]').tooltip();
      }
    });
    $('.dataTables_filter').addClass('pull-right');
    return dt;
  };

  ES.checkForDefaultSearch = function() {
    var urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('hex_id')) {
      var hex_id = urlParams.get('hex_id');
      $('#data_table_filter input[type=search]').val(hex_id);
      return { search: hex_id };
    } else {
      return { search: '' };
    }
  };

  ES.makePlotIconClickable = function(datatable, tableId, dataset, type) {
    $('#' + tableId).on('click', '.close', function() {
      var $tr = $(this).closest('tr').prev()[0];
      var row = datatable.row($tr);
      row.child.hide();
      $tr.removeClass('shown');
    });
    $('#' + tableId).on('click', type, function() {
      var $tr = $(this).closest('tr');
      var id = $tr.find('.pgp_hex_id').text();
      var row = datatable.row($tr);
      ES.openChildRow(row, $tr, dataset, id, type);
    });
  };

  ES.openChildRow = function(row, $tr, dataset, id, type) {
    var child_html;
    if (
      row.child.isShown() &&
      $(row.child()).find(type.replace('.', '#') + id).length === 1
    ) {
      // already open
      row.child.hide();
      $tr.removeClass('shown');
    } else {
      var data = dataset[id];
      if (type == '.report_btn') {
        child_html = ES.openReportsChildRow(data, id, type);
      } else if (type == '.trait_btn') {
        child_html = ES.openTraitsChildRow(data, id, type);
      } else if (type == '.file_btn') {
        child_html = ES.openFilesChildRow(data, id, type);
      }
      row.child(child_html).show();
      $tr.addClass('shown');
    }
  };

  ES.openReportsChildRow = function(data, id, type) {
    var reports_html = $('#child_template')
      .clone()
      .attr('id', type.replace('.', '') + id)
      .show();
    $(reports_html)
      .find('#child_template_header')
      .text('PGP-UK Reports');
    if (
      data.genome_report === undefined &&
      data.methylome_report === undefined
    ) {
      $(reports_html)
        .find('#child_template_body')
        .text(
          'There is no PGP-UK reports currently associated with this participant.'
        );
    } else {
      $(reports_html)
        .find('#child_template_body')
        .append($('<p id="genome_reports">'), $('<p id="methylome_reports">'));
      ES.addReports(data, reports_html, 'genome_report', '#genome_reports');
      ES.addReports(
        data,
        reports_html,
        'methylome_report',
        '#methylome_reports'
      );
    }
    return reports_html;
  };

  ES.addReports = function(data, child_html, type, wrapper_id) {
    if (data[type] == undefined) return;
    for (var i = 0; i < data[type].length; i++) {
      $('<a download="">')
        .addClass('btn btn-lg btn-default')
        .css('margin-right', '5px')
        .attr('type', 'button')
        .attr('href', data[type][i].download_url)
        .append(
          $('<i class="fal fa-lg fa-file-alt">').css('margin-right', '5px'),
          data[type][i].name.replace('Released by PGP-UK on ', '')
        )
        .appendTo($(child_html).find(wrapper_id));
    }
  };

  ES.openTraitsChildRow = function(dataset, id, type) {
    var data = dataset.phenotype[0];
    var traits_html = $('#child_template')
      .clone()
      .attr('id', type.replace('.', '') + id)
      .show();
    $(traits_html)
      .find('#child_template_header')
      .text('Phenotype Data');
    traits_html = ES.updateTraitsHtml(data, traits_html);
    return traits_html;
  };

  ES.updateTraitsHtml = function(data, traits_html) {
    if (data == null) {
      $(traits_html)
        .find('#child_template_body')
        .text(
          'There is no trait data currently associated with this participant.'
        );
    } else {
      for (var i = 0; i < data.length; i++) {
        $('<div>')
          .addClass('question')
          .append(
            $('<p>').append(
              $('<strong>').text(i + 1 + '. ' + data[i].question),
              $('<br>'),
              $('<span>').text(data[i].answer),
              $('<br>')
            )
          )
          .appendTo($(traits_html).find('#child_template_body'));
      }
    }
    return traits_html;
  };

  ES.openFilesChildRow = function(data, id, type) {
    var file_html = $('#child_template')
      .clone()
      .attr('id', type.replace('.', '') + id)
      .show();
    $(file_html)
      .find('#child_template_header')
      .text('PGP-UK Data');
    file_html = ES.addSection(file_html, 'Genome Data', 'genome');
    file_html = ES.addSection(file_html, 'Methylome Data', 'methylome');
    file_html = ES.addSection(file_html, 'Transcriptome Data', 'transcriptome');
    file_html = ES.addSection(file_html, 'User Uploaded Data', 'user_uploaded');
    data = ES.add_section_info(data.download_url);
    file_html = ES.addFileButtonHtml(data, file_html);
    return file_html;
  };

  ES.addSection = function(file_html, title, klass) {
    $(file_html)
      .find('#child_template_body')
      .append(
        $('<div>')
          .addClass(klass + '_parent')
          .css('display', 'none')
          .append(
            $('<h4>').text(title),
            $('<p>')
              .addClass(klass)
              .css('line-height', '3em')
          )
      );
    return file_html;
  };

  ES.add_section_info = function(data) {
    for (var i = 0; i < data.length; i++) {
      type = data[i].type;
      if (type.indexOf('WGBS') !== -1 || type.indexOf('Methylation') !== -1) {
        data[i].section = 'methylome';
      } else if (type.indexOf('Transcriptomic') !== -1) {
        data[i].section = 'transcriptome';
      } else if (type.indexOf('WGS') !== -1 || type.indexOf('VCF') !== -1) {
        data[i].section = 'genome';
      } else if (type.indexOf('23andMe') !== -1) {
        data[i].section = 'user_uploaded';
      }
    }
    return data;
  };

  ES.addFileButtonHtml = function(data, file_html) {
    for (var i = 0; i < data.length; i++) {
      if (data[i].section === undefined) continue;
      var download_url = data[i].download_url;
      if (download_url.startsWith('ftp.')) {
        download_url = 'ftp://' + data[i].download_url;
      }
      $(file_html)
        .find('.' + data[i].section)
        .append(
          $('<a download="">')
            .addClass('btn btn-default')
            .css('margin-right', '10px')
            .attr('type', 'button')
            .attr('href', download_url)
            .append(
              $('<i class="fal fa-lg fa-file-alt">').css('margin-right', '5px'),
              data[i].type
            )
        );
      $(file_html)
        .find('.' + data[i].section + '_parent')
        .show();
    }
    return file_html;
  };
})(); // End of ES module
