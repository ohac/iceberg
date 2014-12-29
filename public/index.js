$(function(){
  var encdigest = $('#encdigest').val();
  if (encdigest) {
    var name = $('#name').val();
    var digest = $('#digest').val();
    localStorage.setItem(encdigest + ':name', name);
    localStorage.setItem(encdigest + ':digest', digest);
  }
  $('.files').each(function(i, x) {
    var y = $(x);
    var id = y.attr('id');
    var digest = localStorage.getItem(id + ':digest');
    if (digest) {
      var name = localStorage.getItem(id + ':name');
      var href = y.attr('href');
      href = href + '?digest=' + digest + '&filename=' + name;
      y.attr('href', href);
      y.html(name);
    }
  });
  var metadata = ''
  var sepa = ''
  for (var i = 0; i < localStorage.length; i++) {
    var k = localStorage.key(i);
    metadata = metadata + sepa + k + '=' + localStorage.getItem(k);
    sepa = '\n';
  }
  $('#metadata').val(metadata);
  $('#apply').click(function () {
    var metadata = $('#metadata').val();
    $(metadata.split('\n')).each(function (i, x) {
      var kv = x.split('=');
      var k = kv[0];
      var v = kv[1];
      if (v) {
        if (v.length == 0) {
          localStorage.removeItem(k);
        }
        else {
          localStorage.setItem(k, v);
        }
      }
    });
    location.href = '/';
  });
  $('#deleteall').click(function () {
    if (confirm('Are you sure?')) {
      localStorage.clear();
    }
  });
});
