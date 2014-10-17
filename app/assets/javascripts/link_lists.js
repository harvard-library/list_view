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
      $rem.find('.links > input').remove();
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
    }
  });
  $(document).on('cocoon:after-insert', function (e, added_item) {
    $(document).scrollTop($(document).scrollTop() + $(added_item).outerHeight());
  });
});
