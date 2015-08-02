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

  var uploaded = sessionStorage.getItem('uploaded');
  sessionStorage.removeItem('uploaded');
  if (uploaded) {
    uploaded = JSON.parse(uploaded);
    var encdigest = uploaded['encdigest'];
    $('#encdigest').val(encdigest);
    var name = uploaded['name'];
    $('#name').val(name);
    var digest = uploaded['digest'];
    $('#digest').val(digest);
    var tripcode = uploaded['tripcode'];
    $('#tripcode').val(tripcode);
    $('#tripkey').val(uploaded['tripkey']);
    $('#uploaded').show();
    var uploadedfile = $('#uploadedfile');
    uploadedfile.text(name);
    uploadedfile.attr('href',
        '/show/' + encdigest + '?digest=' + digest+ '&filename=' + name);
    $('#uploadedshowlocal').attr('href', '/showlocal/' + encdigest);
    var uploadedtrip = $('#uploadedtrip');
    uploadedtrip.text(tripcode);
    uploadedtrip.attr('href', '/tripcode/' + tripcode);
  }

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
    var name = localStorage.getItem(id + ':name');
    var href = y.attr('href');
    if (href.match(/^\/showlocal\//)) {
      if (!digest || !name || !name.match(/\.txt$/)) {
        y.hide();
      }
    }
    else if (digest) {
      href = href + '?digest=' + digest + '&filename=' + name;
      y.attr('href', href);
      y.html(name);
    }
    else if (name) {
      y.html(name + ' (No key)');
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

  $('.uploadtext').click(function(){
    var data = $(this).parent().find('textarea').val();
    var origname = $(this).parent().find('input:first').val() + '.txt';
    origname = origname.replace(/[ #<>:\\/*?"|&',;`]/g, '_')
    var tripkey = $(this).parent().find('.tripin').val();
    var rawdata = CryptoJS.enc.Utf8.parse(data);
    var hash = CryptoJS.SHA1(rawdata).toString();
    var key = CryptoJS.enc.Hex.parse(hash.substring(0, 32));
    var iv = CryptoJS.enc.Hex.parse(hash.substring(8));
    var encrypted = CryptoJS.AES.encrypt(rawdata, key, { iv: iv });
    var str = encrypted.ciphertext.toString(CryptoJS.enc.Base64);
    $.ajax({
      type: 'post',
      url: '/api/v1/uploadraw',
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify({filename: origname, file: str, tripkey: tripkey}),
      success: function(json) {
        var origname = json['origname'];
        var digest = json['encdigest'];
        var tripcode = json['tripcode'];
        var uploaded = JSON.stringify({
          digest: hash,
          encdigest: digest,
          tripcode: tripcode,
          tripkey: tripkey,
          name: origname
        });
        sessionStorage.setItem('uploaded', uploaded);
        window.location.href = '/';
      }
    });
    return false;
  });

});
