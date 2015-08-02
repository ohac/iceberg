$(function(){
  var onerr = function(e) {
    $('#debug').text('error');
  };
  navigator.webkitPersistentStorage.requestQuota(5 * 1024 * 1024,
    function(grantedBytes) {
      window.webkitRequestFileSystem(PERSISTENT, grantedBytes,
        function(fs){
          fs.root.getFile('foo.txt', { create: true },
            function(fe){
              fe.createWriter(
                function(fw) {
                  fw.onwriteend = function(e) {
                    $('#debug').text('wrote!');
                    fs.root.getFile('foo.txt', {},
                      function(fe){
                        fe.file(function(file) {
                            var reader = new FileReader();
                            reader.onloadend = function(e) {
                              $('#debug').text(this.result);
                            };
                            reader.readAsText(file);
                          },
                          onerr
                        );
                      },
                      onerr
                    );
                  };
                  fw.onerror = onerr;
                  var blob = new Blob(['hello!'], {type: 'text/plain'});
                  fw.write(blob);
                },
                onerr
              );
            },
            onerr
          );
        },
        onerr
      );
    },
    onerr
  );
});
