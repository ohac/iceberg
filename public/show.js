$(function(){
  var encdigest = $('#encdigest').val();
  if (encdigest) {
    var name = $('#name').val();
    var digest = $('#digest').val();
    localStorage.setItem(encdigest + ':name', name);
    localStorage.setItem(encdigest + ':digest', digest);
  }
  $('#apply').click(function () {
    var textdata = $('#textdata');
    if (textdata) {
      //var metadata = textdata.contents()[0].body.innerHTML;
      var metadata = $('pre', textdata.contents()).text(); // TODO Chrome only?
      $(metadata.split('\n')).each(function (i, x) {
        var kv = x.split('=');
        var k = kv[0];
        var v = kv[1];
        if (!!v) {
          if (v.length == 0) {
            localStorage.removeItem(k);
          }
          else {
            localStorage.setItem(k, v);
          }
        }
        else if (k) {
          localStorage.removeItem(k);
        }
      });
    }
  });
});
