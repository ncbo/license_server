$(document).ready(function () {
});

function renderTable() {
  var licTable = $('#licenses').dataTable({
    "order": []
  });
}

$(".licenses.index").ready(function() {
  // display licenses table on load
  renderTable();
});