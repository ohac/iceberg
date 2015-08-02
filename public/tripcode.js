$(function(){
  var title = document.title;
  var tripcode = $('#tripcode').val();
  var tagname = localStorage.getItem(tripcode + ':title');
  if (tagname) {
    document.title = tagname + ' - ' + title;
    $('#maintitle').text(tagname);
  }
  var tripcodelist = localStorage.getItem('tripcodelist');
  if (tripcodelist && tripcodelist.indexOf(tripcode) >= 0) {
    $('#star').text('Unstar');
  }
  $('#starbtn').click(function() {
    var tripcodelist = localStorage.getItem('tripcodelist');
    var s = $('#star').text();
    var starred = s == 'Unstar';
    if (tripcodelist) {
      if (starred) {
        var nl = $.grep(tripcodelist.split(','), function(v) {
          return v != tripcode;
        });
        tripcodelist = nl.join(',');
      }
      else {
        tripcodelist += ',' + tripcode;
      }
    }
    else {
      if (starred) { alert('BUG: tripcode.js'); }
      else {
        tripcodelist = tripcode;
      }
    }
    localStorage.setItem('tripcodelist', tripcodelist);
    $('#star').text(starred ? 'Star' : 'Unstar');
  });
  $('#settagname').click(function() {
    localStorage.setItem(tripcode + ':title', $('#tagname').val());
    location.reload();
  });
  $('.files').each(function(i, x) {
    var y = $(x);
    var id = y.attr('id');
    var digest = localStorage.getItem(id + ':digest');
    if (digest) {
      var name = localStorage.getItem(id + ':name');
      var href = y.attr('href');
      if (href.match(/^\/showlocal\//)) {
        if (!name.match(/\.txt$/)) {
          y.hide();
        }
      }
      else {
        href = href + '?digest=' + digest + '&filename=' + name;
        y.attr('href', href);
        y.html(name);
      }
    }
  });
});
