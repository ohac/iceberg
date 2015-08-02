$(function(){
  var encdigest = $('#encdigest').val();
  var name = localStorage.getItem(encdigest + ':name');
  $('h1').text(name);
  document.title = name + ' - ' + document.title;
  $.ajax({
    type: 'get',
    url: '/api/v1/download/' + encdigest,
    dataType: 'binary',
    processData: false,
    success: function(encdata) {
      var textdata = $('#textdata');
      var digest = localStorage.getItem(encdigest + ':digest');
      var key = CryptoJS.enc.Hex.parse(digest.substring(0, 32));
      var iv = CryptoJS.enc.Hex.parse(digest.substring(8));
      var reader = new FileReader();
      reader.readAsArrayBuffer(encdata);
      reader.onload = function(ev){
        var arrayBuffer = ev.target.result;
        var u8a = new Uint8Array(arrayBuffer);
        var wa = CryptoJS.lib.WordArray.create(u8a);
        var decrypted = CryptoJS.AES.decrypt(CryptoJS.enc.Base64.stringify(wa),
            key, { iv: iv });
        textdata.val(decrypted.toString(CryptoJS.enc.Utf8));
      };
    }
  });
});
