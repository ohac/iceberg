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
});
