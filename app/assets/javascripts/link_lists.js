$(function () {
  $(document).on('cocoon:after-remove', function (e, removed_item) {
    $(removed_item).show();
    $(removed_item).addClass('deleted');
  });
});
