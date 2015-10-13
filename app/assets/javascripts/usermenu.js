$(function() {

	var dialogBaseOpts = {
	    modal: true,
	    draggable: false,
	    resizable: false,
	    width: "90%",
	    classes: "qtip-bootstrap",
	    close: function (e) { $(this).remove()}
	  };
	
  //Handlebars comparison handler for related links filtering
  Handlebars.registerHelper('isLink', function (link, options) {
    var isLink = link.toLowerCase().indexOf('http') > -1 ? true : false;
    if (isLink)
      return options.fn(this);
    else
      return options.inverse(this);
  });

  // Compile Handlebars templates into t
  var t = {};
  $('script[type="text/x-handlebars-template"]').each(function () {
    t[this.id] = Handlebars.compile(this.innerHTML);
  });

  var call_operation = function (e) {
    e.preventDefault();   
    var op = e.currentTarget.id;
    
    var uri = window.location.href,
		parts = uri.split("/"),
		last_idx = parts.length - 1,
	 	drs_match = parts[last_idx].match(/drs-(\d+)/),
	 	drs_id = drs_match && drs_match[1];
	if (drs_match) {
		operations[op](drs_id);
	}
	else {
      //TODO - display error dialog?
    }
   
  };
  var operations = {
    "cite": function (drs_id) {
      var $dialog = $('#citation-modal');
      
      if ($dialog.get().length > 0) {
    	  $dialog.dialog('close');
      }
      else {
    	var pdsurl = $("#pds-ws-url").val();
    	$dialog = $('<div id="citation-modal" style="display:none" />');
    	$dialog.html('blah');
    	//$dialog.html(t['citation-tmpl'])({urn: "urn", description: "description", repository: "repository", institution: "inst", accessed: "acc"});
    	$dialog.appendTo('body');
    	/*$.getJSON( pdsurl + '/cite/400079411', {n:1})
          .done(function (data) {
            if (data.citation) {
              $dialog.html(t['citation-tmpl'](data.citation));
              $dialog.appendTo('body');
              $dialog
                .dialog($.extend({title: "Citation"}, dialogBaseOpts))
                .dialog('open');
            } //TODO: Else graceful error display
          });*/
    	$dialog
          .dialog($.extend({title: "Citation"}, dialogBaseOpts))
          .dialog('open');
      }
    },
    "print": function(drs_id, n, slot_idx) {
      var cSlot = Mirador.viewer.workspace.slots[slot_idx];
      var cWindow = cSlot.window;
      var citLabel = cWindow.manifest.jsonLd.label;
      var content = { drs_id: drs_id, n: n, slot_idx: slot_idx, label: citLabel };
      var $dialog = $('#print-modal');

      if ($dialog.get().length > 0) {
        $dialog.dialog('close');
      }
      else {
        $dialog = $('<div id="print-modal" style="display:none" />');
        $dialog.html(t['print-tmpl'](content));
        $dialog
          .dialog($.extend({title: "Convert to PDF for Printing"}, dialogBaseOpts))
          .dialog('open');

        //set default print range max/min values
        $('#start').val('1');
        var print_slot_idx = $("#print_slot_idx").val();
        var totalSeq = Mirador.viewer.workspace.slots[print_slot_idx].window.imagesList.length;
        $('#end').val(totalSeq);

        $('input#pdssubmit').click(function(e) {
         e.preventDefault();
         printPDF(e);
        });
        $('input#pdsclear').click(function(e) {
          $('#email').val('');
          $('#start').val('1');
          $('#end').val(totalSeq);
          $('#printmsg').html('&nbsp;');
          $('input[name=printOpt]:checked').prop('checked', false);
          $('#printOptDefault').prop('checked', 'checked');
        });
      }
    },
    "relatedlinks": function (drs_id) {
      var $dialog = $('#links-modal');

      if ($dialog.get().length > 0) {
        $dialog.dialog('close');
      }
      else {
    	var pdsurl = $("pds-ws-url");
        $dialog = $('<div id="links-modal" style="display:none" />');
        $.get(pdsurl + '/related/' + drs_id, function(xml){
          var json = $.xml2json(xml);
          if (json.link) {
            // Normalize to array for Handlebars
            if (!json.link.length) { json.link = [json.link]}

            $dialog.html(t['links-tmpl']({links: json.link, op: "relatedlinks", citation: json.citation}));
            $dialog.appendTo('body');
            $dialog
                .dialog($.extend({title: 'Related Links'}, dialogBaseOpts))
                .dialog('open');
          }
        }); //TODO: Else graceful error display
      }
    }

  };

  //$(document).on('click', "a.cite, a.relatedlinks", call_operation);

});
