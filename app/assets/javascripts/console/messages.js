$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'messages/qanda')){

    // 設定 sortable
    $( "ul#sortable" ).sortable({
      revert: true,
      stop: function(){
        renew_index();
      }
    });

    // 讓元素內的文字無法被選取
    $( "li" ).disableSelection();

    // 非公開區的問題可拖曳至 #sortable(公開區)
    $( "li.draggable" ).draggable({
      connectToSortable: "#sortable",
      revert: "invalid"
    });

    // #sortable 的問題按 x 可丟到非公開區
    $('#sortable_block .x').click(function(){
      $li = $(this).parent('li');
      $li.removeClass('list-group-item-success ui-sortable-handle').addClass('list-group-item-danger draggable ui-draggable ui-draggable-handle');
      $li.children('span').text('');
      $('#drag_box').append($li);
      renew_index();
    });

  }
});

// 問題編號依順序更新
function renew_index(){
  i = 1;
  $('#sortable li .index').each(function(){
    $(this).text(i+'.');
    i++;
    $(this).next('.x').text('X');
  });
}

// 更新 Q&A submit
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

// #sortable 內的問題 click 可以拖曳
function dragAnswer(){
  $( ".draggable" ).draggable({
    connectToSortable: "#sortable",
    revert: "invalid"
  });
}


