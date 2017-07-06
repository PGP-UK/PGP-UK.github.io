var ES; // define global ES (acronym for EBI_Search)  object
if (!ES) { ES = { 'data': [] }; }

(function() { // ES module
  ES.init = function() {
    $.getJSON('https://pgp-uk.github.io/data/json/data.json', function(json) {
      ES.initializeTable(json, 'table', 'table-wrapper');
    });
  };


  ES.initializeTable = function(dataset, tableId, tableWrapperId) {
    console.log(dataset);
    dataset = ES.addPlotIconToTopTable(dataset);
    var dt = $('#' + tableId).dataTable({
      data: dataset,
      iDisplayLength: 30,
      pagingType: 'full',
      order: [
        [0, "asc"]
      ],
      bAutoWidth: false
    });
  };
}()); // End of ES module
