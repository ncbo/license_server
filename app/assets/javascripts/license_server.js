var latestOnly = false;

function toggleShow(val) {
  latestOnly = val;
}

$(document).ready(function () {
  $("#copy-button").click(function() {
    copyToClipboard(document.getElementById("license-key"));
    $(this).html('<img src="data:image/svg+xml;utf8;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pgo8IS0tIEdlbmVyYXRvcjogQWRvYmUgSWxsdXN0cmF0b3IgMTkuMS4wLCBTVkcgRXhwb3J0IFBsdWctSW4gLiBTVkcgVmVyc2lvbjogNi4wMCBCdWlsZCAwKSAgLS0+CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgdmVyc2lvbj0iMS4xIiBpZD0iQ2FwYV8xIiB4PSIwcHgiIHk9IjBweCIgdmlld0JveD0iMCAwIDQ4OC4zIDQ4OC4zIiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA0ODguMyA0ODguMzsiIHhtbDpzcGFjZT0icHJlc2VydmUiIHdpZHRoPSIxNnB4IiBoZWlnaHQ9IjE2cHgiPgo8Zz4KCTxnPgoJCTxwYXRoIGQ9Ik0zMTQuMjUsODUuNGgtMjI3Yy0yMS4zLDAtMzguNiwxNy4zLTM4LjYsMzguNnYzMjUuN2MwLDIxLjMsMTcuMywzOC42LDM4LjYsMzguNmgyMjdjMjEuMywwLDM4LjYtMTcuMywzOC42LTM4LjZWMTI0ICAgIEMzNTIuNzUsMTAyLjcsMzM1LjQ1LDg1LjQsMzE0LjI1LDg1LjR6IE0zMjUuNzUsNDQ5LjZjMCw2LjQtNS4yLDExLjYtMTEuNiwxMS42aC0yMjdjLTYuNCwwLTExLjYtNS4yLTExLjYtMTEuNlYxMjQgICAgYzAtNi40LDUuMi0xMS42LDExLjYtMTEuNmgyMjdjNi40LDAsMTEuNiw1LjIsMTEuNiwxMS42VjQ0OS42eiIgZmlsbD0iI0ZGRkZGRiIvPgoJCTxwYXRoIGQ9Ik00MDEuMDUsMGgtMjI3Yy0yMS4zLDAtMzguNiwxNy4zLTM4LjYsMzguNmMwLDcuNSw2LDEzLjUsMTMuNSwxMy41czEzLjUtNiwxMy41LTEzLjVjMC02LjQsNS4yLTExLjYsMTEuNi0xMS42aDIyNyAgICBjNi40LDAsMTEuNiw1LjIsMTEuNiwxMS42djMyNS43YzAsNi40LTUuMiwxMS42LTExLjYsMTEuNmMtNy41LDAtMTMuNSw2LTEzLjUsMTMuNXM2LDEzLjUsMTMuNSwxMy41YzIxLjMsMCwzOC42LTE3LjMsMzguNi0zOC42ICAgIFYzOC42QzQzOS42NSwxNy4zLDQyMi4zNSwwLDQwMS4wNSwweiIgZmlsbD0iI0ZGRkZGRiIvPgoJPC9nPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+Cjwvc3ZnPgo="> <span id="copy-button-text">Copied!</span>');
  });
});

function renderTable() {
  var licTable = $('#licenses').DataTable({
    "order": [],
    "stripeClasses": [],
    "dom": "<'row'" +
      "<'col-sm-12 col-md-5'<'new-license-button-span'>>" +
      "<'col-sm-12 col-md-2'l>" +
      "<'col-sm-12 col-md-2'<'show-license-toggle'>>" +
      "<'col-sm-12 col-md-3'f>>" +
      "<'row'" +
      "<'col-sm-12'tr>>" +
      "<'row'" +
      "<'col-sm-12 col-md-5'i>" +
      "<'col-sm-12 col-md-7'p>>",
    columnDefs: [{
      targets: 'no-sort',
      orderable: false,
      searchable: false
    }],
    "customAllowLicensesFilter": true
  });
  return licTable;
}

$(".licenses.index").ready(function() {
  // display licenses table on load
  licTable = renderTable();
  $("div.show-license-toggle").html('<span class="toggle-row-display">' + showLicensesToggleLinks(latestOnly) + '</span>');
  $("div.new-license-button-span").html('<form class="button_to" method="get" action="/licenses/new"><input class="button button-blue" type="submit" value="Create License for New Appliance"></form>');
  $(".toggle-row-display").on("click", "a", function() {
    toggleShow(!latestOnly);
    licTable.draw();
    str = showLicensesToggleLinks(latestOnly);
    $(".toggle-row-display").html(str);
    return false;
  });

  // toggle between all and latest only licenses
  $.fn.dataTable.ext.search.push(
    function(settings, data, dataIndex) {
      if (!settings.oInit.customAllowLicensesFilter) {
        return true;
      }
      var row = settings.aoData[dataIndex].nTr;

      if (!latestOnly || row.classList.contains("latest")) {
        return true;
      }
      return false;
    }
  );
});

function showLicensesToggleLinks(latestOnly) {
  var str = 'Show Licenses:&nbsp;&nbsp;&nbsp;';

  if (latestOnly) {
    str += '<a id="showAllLicensesAction" href="javascript:;">All</a>&nbsp;&nbsp;|&nbsp;&nbsp;<strong>Latest</strong>';
  } else {
    str += '<strong>All</strong>&nbsp;&nbsp;|&nbsp;&nbsp;<a id="showLatestLicensesAction" href="javascript:;">Latest</a>';
  }
  return str;
}

function copyToClipboard(elem) {
  // create hidden text element, if it doesn't already exist
  var targetId = "_hiddenCopyText_";
  var isInput = elem.tagName === "INPUT" || elem.tagName === "TEXTAREA";
  var origSelectionStart, origSelectionEnd;
  if (isInput) {
    // can just use the original source element for the selection and copy
    target = elem;
    origSelectionStart = elem.selectionStart;
    origSelectionEnd = elem.selectionEnd;
  } else {
    // must use a temporary form element for the selection and copy
    target = document.getElementById(targetId);
    if (!target) {
      var target = document.createElement("textarea");
      target.style.position = "absolute";
      target.style.left = "-9999px";
      target.style.top = "0";
      target.id = targetId;
      document.body.appendChild(target);
    }
    target.textContent = elem.textContent;
  }
  // select the content
  var currentFocus = document.activeElement;
  target.focus();
  target.setSelectionRange(0, target.value.length);

  // copy the selection
  var succeed;
  try {
    succeed = document.execCommand("copy");
  } catch(e) {
    succeed = false;
  }
  // restore original focus
  if (currentFocus && typeof currentFocus.focus === "function") {
    currentFocus.focus();
  }

  if (isInput) {
    // restore prior selection
    elem.setSelectionRange(origSelectionStart, origSelectionEnd);
  } else {
    // clear temporary content
    target.textContent = "";
  }
  return succeed;
}