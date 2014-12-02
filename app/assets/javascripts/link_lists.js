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
  // Copied from console, needs much adjustment.
  $(document).on('click', '.btn.meta', function (e) {
    e.preventDefault();
    $.getJSON('/meta/' + $('#link_list_ext_id_type').val() + '/' + $('#link_list_ext_id').val())
      .done(function (data, status, jqXHR) {
        if (data['body']) {
          $('#modal-metadata .modal-field-title .content').text(data.title)
          $('#modal-metadata .modal-field-author .content').text(data.author)
          $('#modal-metadata .modal-field-publication .content').text(data.publication)
          $('#modal-metadata .modal-fields').show();
          $('#modal-metadata .modal-blank').hide();
          $('#modal-metadata .btn.meta-accept').show();
        }
        else {
          $('#modal-metadata .modal-blank').show();
          $('#modal-metadata .modal-fields').hide();
          $('#modal-metadata .btn.meta-accept').hide();
        }
        $('#modal-metadata').modal()
      })
      .fail(function (data, status, jqXHR) {
        $('#modal-metadata .modal-blank').show();
        $('#modal-metadata .modal-fields').hide();
        $('#modal-metadata .btn.meta-accept').hide();
        $('#modal-metadata').modal()
      })
  });

  $(document).on('click', '.btn.meta-accept', function (e) {
    $('#link_list_title').val($('#modal-metadata .modal-field-title .content').text());
    $('#link_list_author').val($('#modal-metadata .modal-field-author .content').text());
    $('#link_list_publication').val($('#modal-metadata .modal-field-publication .content').text());

    if ($('#link_list_title').offset().top < $(document).scrollTop()) {
      $('#link_list_title').parent().get()[0].scrollIntoView(true);
    }
    else if ( ($(document).scrollTop() + $(window).height()) < ($('#link_list_publication').offset().top + $('#link_list_publication').height()) ){
      $('#link_list_title').parent().get()[0].scrollIntoView(true);
    }
    highlight($('#link_list_title, #link_list_author, #link_list_publication').get())
  });
});
