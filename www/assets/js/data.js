var PGP; // define global PGP (acronym for Personal Genome Project UK)  object
if (!PGP) {
  PGP = {};
}

(function() {
  // PGP module
  PGP.API_VERSION = 'v1.1';
  PGP.init = function() {
    if (PGP.table_json !== undefined) {
      PGP.initializeTable('#data_table');
      PGP.makePlotIconClickable('#data_table', '.file_btn');
      PGP.makePlotIconClickable('#data_table', '.report_btn');
      PGP.makePlotIconClickable('#data_table', '.trait_btn');
    } else {
      PGP.fetchDataAndInit();
    }
  };

  PGP.fetchDataAndInit = function() {
    $.getJSON('/data/json/table.json', function(json) {
      PGP.table_json = json;
      PGP.initializeTable('#data_table');
      var apiUrl = '/api/' + PGP.API_VERSION + '/all_participants.json'
      $.getJSON(apiUrl, function(data_json) {
        PGP.data_json = data_json;
        PGP.makePlotIconClickable('#data_table', '.file_btn');
        PGP.makePlotIconClickable('#data_table', '.report_btn');
        PGP.makePlotIconClickable('#data_table', '.trait_btn');
      });
    });
  }

  PGP.initializeTable = function(selector) {
    if ($(selector).length == 0) return;
    if (PGP.table_json === undefined) return;
    if (PGP.datatable !== undefined) return;

    PGP.datatable = $(selector).DataTable({
      data: PGP.table_json,
      responsive: true,
      iDisplayLength: 10,
      pagingType: 'full',
      order: [[0, 'asc']],
      search: PGP.checkForDefaultSearch(),
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
  };

  PGP.checkForDefaultSearch = function() {
    var urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('hex_id')) {
      var hex_id = urlParams.get('hex_id');
      $('#data_table_filter input[type=search]').val(hex_id);
      return { search: hex_id };
    } else {
      return { search: '' };
    }
  };

  PGP.makePlotIconClickable = function(tableSelector, type) {
    if (PGP.data_json === undefined) return;
    if (PGP.datatable === undefined) return;

    $(tableSelector).on('click', '.close', function() {
      var tr = $(this)
        .closest('tr')
        .prev()[0];
      var row = PGP.datatable.row(tr);
      row.child.hide();
      $(tr).removeClass('shown');
    });
    $(tableSelector).on('click', type, function() {
      var $tr = $(this).closest('tr');
      var id = $tr.find('.pgp_hex_id').text();
      var row = PGP.datatable.row($tr);
      PGP.openChildRow(row, $tr, PGP.data_json, id, type);
    });
  };

  PGP.openChildRow = function(row, $tr, dataset, id, type) {
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
        child_html = PGP.openReportsChildRow(data, id, type);
      } else if (type == '.trait_btn') {
        child_html = PGP.openTraitsChildRow(data, id, type);
      } else if (type == '.file_btn') {
        child_html = PGP.openFilesChildRow(data, id, type);
      }
      if (child_html != undefined) {
        row.child(child_html).show();
        $tr.addClass('shown');
      }
    }
  };

  PGP.openReportsChildRow = function(data, id, type) {
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
      PGP.addReports(data, reports_html, 'genome_report', '#genome_reports');
      PGP.addReports(
        data,
        reports_html,
        'methylome_report',
        '#methylome_reports'
      );
    }
    return reports_html;
  };

  PGP.addReports = function(data, child_html, type, wrapper_id) {
    if (data[type] == undefined) return;
    for (var i = 0; i < data[type].length; i++) {
      $('<a download="">')
        .addClass('btn btn-3d btn-default btn-icon-left btn-lg')
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

  PGP.openTraitsChildRow = function(dataset, id, type) {
    var data;
    var traits_html = $('#child_template')
      .clone()
      .attr('id', type.replace('.', '') + id)
      .show();
    $(traits_html)
      .find('#child_template_header')
      .text('Phenotype Data');
    if (dataset.phenotype == undefined) {
      data = null;
    } else {
      data = dataset.phenotype[0];
    }
    traits_html = PGP.updateTraitsHtml(data, traits_html);
    return traits_html;
  };

  PGP.updateTraitsHtml = function(data, traits_html) {
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

  PGP.openFilesChildRow = function(data, id, type) {
    var file_html = $('#child_template')
      .clone()
      .attr('id', type.replace('.', '') + id)
      .show();
    $(file_html)
      .find('#child_template_header')
      .text('PGP-UK Data');
    file_html = PGP.addSection(file_html, 'Genome Data', 'genome');
    file_html = PGP.addSection(file_html, 'Methylome Data', 'methylome');
    file_html = PGP.addSection(file_html, 'Transcriptome Data', 'transcriptome');
    file_html = PGP.addSection(file_html, 'User Uploaded Data', 'user_uploaded');
    data = PGP.add_section_info(data.download_url);
    file_html = PGP.addFileButtonHtml(data, file_html);
    return file_html;
  };

  PGP.addSection = function(file_html, title, klass) {
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

  PGP.add_section_info = function(data) {
    if (data == undefined) return;
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

  PGP.addFileButtonHtml = function(data, file_html) {
    if (data == undefined) return;
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
            .addClass('btn btn-3d btn-default btn-icon-left btn-lg')
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
})(); // End of PGP module
