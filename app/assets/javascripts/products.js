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

});

//click cat1
function cat1(object){
  $("input[name='cat2_field[]']").remove();
  $(".cat2_tag").remove();
  $('#cat2').slideDown(); //#cat2 slideDown
  
  tagName = $(object).data('name');
  tagId = $(object).data('id');

  if(tagName == $('#cat1_field').val()){
    destroy($('#cat1-tag-'+tagId), 1,);
  }else{
    $('#cat1 div').css({'background-color': 'transparent', 'color': '#000000'}); //復原全部cat1
    $(object).css({'background-color': '#800000', 'color': '#ffffff'});

    $('#cat1_field').val(tagName);

    $('.cat1_tag').remove();
    tag_create(tagName, tagId, 1);
  }

  $('#cat2_click').val('');
  form_submit();
}

function cat2(object){
  tagId = $(object).data('id');
  tagName = $(object).data('name');
  tagCat1 = $(object).data('cat1');

  var onSelect = document.getElementById('cat2-input-'+tagId);

  if(onSelect === null){ //沒被選過 -> 選擇分類
    $(object).css({'background-color': '#bc8f8f', 'color': '#ffffff'});
    
    var input = document.createElement('input');
    input.type = 'hidden'
    input.name = 'cat2_field[]';
    input.value = tagId;
    input.id = 'cat2-input-'+tagId;
    document.getElementById('search_form').appendChild(input);

    tag_create(tagName, tagId, 2);


  }else{ //已被選過 -> 刪除分類
    destroy($('#cat2-tag-'+tagId), 2);
  }  
  $('#cat2_click').val('true');
  form_submit(); 
}

function tag_create(tagName, tagId, n){
  //分類的tag
  var selectBubble = document.createElement('div');
  var bubbleText = document.createTextNode(tagName+' x'); //文字
  selectBubble.appendChild(bubbleText);
  selectBubble.id = 'cat'+n+'-tag-'+tagId;
  selectBubble.className = 'cat'+n+'_tag'; //class
  selectBubble.setAttribute('onclick', "destroy(this, "+n+")");
  selectBubble.setAttribute('data-id', tagId);
  document.getElementById('tag').appendChild(selectBubble);
}

function destroy(object, cat){
  tagId = $(object).data('id');
  if(cat == 1){
    $('#cat1-box-'+tagId).css({'background-color': 'transparent', 'color': '#000000'});
    $('#cat1-tag-'+tagId).remove();
    $('#cat1_field').val('');
    $('.cat2_tag').each(function(){
      destroy(this, 2);
    });
    $('#cat2').slideUp();

  }else if(cat == 2){
    $('#cat2-box-'+tagId).css({'background-color': 'transparent', 'color': '#000000'});
    $('#cat2-tag-'+tagId).remove();
    $('#cat2-input-'+tagId).remove();
  }
  form_submit();
}

function clear_tag(){
  console.log('aa');
  $('#price_bottom').val('');
  $('#price_bottom').val('');
  $('.cat1_tag').each(function(){
    destroy(this, 1);
  });
  $('.cat2_tag').each(function(){
    destroy(this, 2);
  });
  form_submit();
}

function form_submit(){
  $('#search_form').submit();
}


/*
  box/input/tag attribute
  >>cat1-box
  id="cat1-box-0"
  data-name="電子產品" 
  data-id="0"
  data-target="#cat2" 
  onclick="cat1(this);"

  >>cat2-box
  id="cat2-box-4"
  data-name="肉品"
  data-cat1="1" 
  data-category="cat2" 
  data-id="4"  
  onclick="cat2(this);"

  >>cat1-tag
  id="cat1-tag-0" 
  class="cat1_tag" 
  onclick="destroy(this)" 
  data-id="0"

  >>cat2-tag
  id="cat2-tag-2" 
  class="cat2_tag" 
  onclick="destroy(this)" 
  data-id="2"

  >>cat1-input
  name="cat1_field" 
  id="cat1_field" 
  value="電子產品"

  >>cat2-input
  name="cat2_field[]" 
  id="cat2-input-2"
  value="2" 
*/
