$(function () {
  $(document).on('cocoon:before-remove', function (e, removed_item) {
    $rem = $(removed_item);
    if ($rem.hasClass('deleted')){
      $rem.addClass('undelete');
    }
  });
  $(document).on('cocoon:after-remove', function (e, removed_item) {
    $rem.show();
    $rem = $(removed_item);
    if ($rem.hasClass('undelete')) {
      $rem.find('.links input').val('false');
      $rem.removeClass('deleted').removeClass('undelete')
      $rem.find('.links > a')
        .removeClass('btn-warning')
        .addClass('btn-danger')
        .text('Remove');
    }
    else {
      $rem.addClass('deleted');
      $rem.find('.links > a')
        .removeClass('btn-danger')
        .addClass('btn-warning')
        .text('Restore')
      $rem.find('.links input').val('1');
    }
  });
  $(document).on('cocoon:after-insert', function (e, added_item) {
    $(document).scrollTop($(document).height() -$(window).height());
    highlight(added_item);
  });

  var resize_fixed_fieldset = function () {
    $('fieldset.form-actions').width( $('fieldset.inputs').width() + 1 );
  }

  $(document).on('ready page:load', resize_fixed_fieldset);
  $(window).on('resize', resize_fixed_fieldset);

  var highlight = function (thing) {
    var $me = $(thing);
    var oc = $me.css('background-color');

    $me.animate({backgroundColor: hollis_links.colors.creme}, 300)
      .animate({backgroundColor: oc}, 300)
      .promise('fx')
      .done(function () {
        $me.css('backgroundColor', '')
      })
  }

});
