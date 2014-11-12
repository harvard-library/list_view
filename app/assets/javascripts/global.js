$(function () {
  var spinnerTimeout;

  $(document).on('page:fetch', function () {
    spinnerTimeout = setTimeout(function () {
      $('body').prepend($('<div id="tl-loading-spinner">Loading...</div>').hide());
      $('#tl-loading-spinner').fadeIn(200);
    }, 500);
  });

  $(document).on('ready page:receive', function () {
    console.log('receive');
    clearTimeout(spinnerTimeout);
    $('#tl-loading-spinner').remove();

  });
});
