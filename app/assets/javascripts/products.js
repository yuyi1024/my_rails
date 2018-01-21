$(document).on('turbolinks:load', function() {

  var cat1_tag = '';
  var cat2_tag = '';
  var price_bottom = 0;
  var price_up = 0;
  
  $('#selector .col-sm-3').click(function(){
    $target = $($(this).data('target'));

    if(!$target.is(':visible')){
      $('#boxes').children().each(function(){
        $(this).slideUp();
      });
      $target.slideDown('slow');
    }else{
      $target.toggle('slow');
    }
    
  });

  




});

function cat1(object){
  $target2 = $($(object).data('target'));
  $target2.slideDown();
  $('#cat1_field').val($(object).text());
  $('#cat2_field').val('');

  var selectBubble = document.createElement('div');
  var bubbleText = document.createTextNode($('#cat1_field').val());
  selectBubble.appendChild(bubbleText);
  selectBubble.id = 'ttt';
  document.getElementById('tag').appendChild(selectBubble);

  $('#search_form').submit();
}

function cat2(object){
  $('#cat2_field').val($(object).text());
  $('#search_form').submit();
}

function search(){
  $('#search_form').submit();
}


// var selectBubble = document.createElement("div")
// var bubbleText = document.createTextNode(tagName + ' x')
// selectBubble.className = tagCategory + "_tag"
// selectBubble.id = 'selected-with-tag-id-' + tagId
// selectBubble.appendChild(bubbleText)
// selectBubble.setAttribute('onclick', "destroy('"+tagId+"')");
// document.getElementById("choose").appendChild(selectBubble)

