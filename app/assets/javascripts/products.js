$(document).on('turbolinks:load', function() {

  var cat1_tag = '';
  var cat2_tag = '';
  var price_bottom = 0;
  var price_up = 0;
  
  $('#selector .cat').click(function(){
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

  $('#clear_tag').click(function(){
    $('#cat1_field').val('');
    $('#cat2_field').val('');
    $('#price_bottom').val('');
    $('#price_bottom').val('');
    $('#search_form').submit();
  });

});

//click cat1
function cat1(object){
  $("input[name='cat2_field[]']").remove();
  $target2 = $($(object).data('target')); //->#cat2
  $target2.slideDown(); //#cat2 slideDown
  $('#cat1_field').val($(object).text());

  $('#cat1 div').css({'background-color': 'transparent', 'color': '#000000'}); //復原全部cat1
  $(object).css({'background-color': '#800000', 'color': '#ffffff'});

  $('.cat1_tag').remove();


  //$('.cat2_tag').remove();

  tag_create(1);

  $('#cat2_click').val('');
  $('#search_form').submit();
}

function cat2(object){
  tagId = $(object).data('id');
  tagName = $(object).data('name');
  tagCat1 = $(object).data('cat1');

  var onSelect = document.getElementById('on-select-'+tagId);
  if(onSelect === null){ //沒被選過 -> 選擇分類
    $(object).css({'background-color': '#bc8f8f', 'color': '#ffffff'});
    
    var input = document.createElement('input');
    input.type = 'hidden'
    input.name = 'cat2_field[]';
    input.value = tagId;
    input.id = 'on-select-'+tagId;
    document.getElementById('search_form').appendChild(input);

  }else{ //已被選過 -> 刪除分類
    $(object).css({'background-color': 'transparent', 'color': '#000000'});
    $('#on-select-'+tagId).remove();
  }
  
  $('#cat2_click').val('true');
  $('#search_form').submit();
  
}




function tag_create(n){
  //分類的tag
  var selectBubble = document.createElement('div');
  var bubbleText = document.createTextNode($('#cat'+n+'_field').val());
  selectBubble.appendChild(bubbleText);
  // selectBubble.id = 'ttt';
  selectBubble.className = 'cat'+n+'_tag';
  selectBubble.setAttribute('onclick', "destroy(this)");
  document.getElementById('tag').appendChild(selectBubble);
}



function search(){
  $('#search_form').submit();
}

function destroy(object){
  $(object).remove();
}
//  selectBubble.setAttribute('onclick', "destroy('"+tagId+"')");




