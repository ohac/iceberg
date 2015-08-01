$(function(){
  Math.seedrandom();
  function reseed(event, count) {
    var t = [];
    function w(e) {
      t.push([e.pageX, e.pageY, +new Date]);
      if (t.length < count) { return; }
      document.removeEventListener(event, w);
      Math.seedrandom(t, { entropy: true });
    }
    document.addEventListener(event, w);
  }
  reseed('mousemove', 100);
  $('.autogen').click(function() {
    var tripcode = Math.random();
    $('.tripin').val(tripcode);
  });

  var lasttripkey = localStorage.getItem('lasttripkey');
  $('.tripin').val(lasttripkey);

  var encdigest = $('#encdigest').val();
  if (encdigest) {
    var name = $('#name').val();
    var digest = $('#digest').val();
    var tripcode = $('#tripcode').val();
    var tripkey = $('#tripkey').val();
    localStorage.setItem(encdigest + ':name', name);
    localStorage.setItem(encdigest + ':digest', digest);
    localStorage.setItem('lasttripkey', tripkey);
    if (tripcode) {
      var list = localStorage.getItem('tripcodelist');
      if (list) {
        if (list.indexOf(tripcode) < 0) {
          localStorage.setItem('tripcodelist', list + ',' + tripcode);
        }
      }
      else {
        localStorage.setItem('tripcodelist', tripcode);
      }
    }
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
    else {
      y.hide();
    }
  });
  $('.tripcodelist').each(function(i, x) {
    var y = $(x);
    var id = y.attr('id');
    var tripcodelist = localStorage.getItem('tripcodelist');
    var star = '<span class="glyphicon glyphicon-star" aria-hidden="true">' +
        '</span>';
    var html = y.html();
    var tagname = localStorage.getItem(id + ':title');
    tagname = tagname ? tagname : ('Untitled Tag ' + id);
    html = tagname;
    if (tripcodelist && tripcodelist.indexOf(id) >= 0) {
      html = star + html;
    }
    y.html(html);
  });
  $('#showkeys').click(function () {
    var metadata = ''
    var sepa = ''
    for (var i = 0; i < localStorage.length; i++) {
      var k = localStorage.key(i);
      metadata = metadata + sepa + k + '=' + localStorage.getItem(k);
      sepa = '\n';
    }
    $('#metadata').val(metadata);
  });
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
  $(":file").filestyle({input: false, icon: true, size: 'lg'});
  $('#uploadtabs a').click(function (e) {
    e.preventDefault()
    $(this).tab('show')
  });
});
