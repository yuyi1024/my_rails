$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'messages/qanda')){

    $( "#sortable" ).sortable({
      revert: true,
      stop: function(){
        renew_index();
      }
    });

    $( "li" ).disableSelection();

    $( ".draggable" ).draggable({
      connectToSortable: "#sortable",
      revert: "invalid"
    });

    $('#sortable_block .x').click(function(){
      $li = $(this).parent('li');
      $li.removeClass('list-group-item-success ui-sortable-handle').addClass('list-group-item-danger draggable ui-draggable ui-draggable-handle');
      $li.children('span').text('');
      $('#drag_box').append($li);
      renew_index();
    });

  }
});

function messageSearch(){
  $('#search_filter').submit();
}

function renew_index(){
  i = 1;
  $('#sortable li .index').each(function(){
    $(this).text(i+'.');
    i++;
    $(this).next('.x').text('X');
  });

}

function sortable(){
  var qanda = [];
  var holding = [];

  $('#sortable li').each(function(){
    qanda.push($(this).data('id'));
  });

  $('#drag_box li').each(function(){
    holding.push($(this).data('id'));
  });
  
  $.ajax({
    type: 'POST',
    url: '/console/messages/sort_qanda',
    data : {
      qanda: qanda,
      holding: holding
    },
  });
}


function dragAnswer(){
  $( ".draggable" ).draggable({
    connectToSortable: "#sortable",
    revert: "invalid"
  });
}


