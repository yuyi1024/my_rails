$(document).on('turbolinks:load', function() {
  
  // var path = window.location.pathname;
  var location = window.location;

  if (location.pathname == '/' || (location.pathname.match(/products/g) && location.pathname.match(/console/g) == null)){

    $('#banner').slick({
      autoplay: true,
      autoplaySpeed: 2000,
      arrows: false,
      dots: true,
      pauseOnHover: false,
    });

    var price_bottom = 0;
    var price_up = 0;

    $('#selector .cat').click(function() {
      $target = $($(this).data('target'));

      if (!$target.is(':visible')) {
        $('#boxes').children().each(function() {
          $(this).slideUp();
        });
        $('span.glyphicon-chevron-left').css('transform', 'rotate(-90deg)');
        $('#boxes').addClass('boxes_visible');
        $target.slideDown('slow');
      } else {
        $('span.glyphicon-chevron-left').css('transform', 'rotate(0deg)');
        $('#boxes').removeClass('boxes_visible');
        $target.toggle('slow');
      }

    });


    $('.input-quantity span').click(function(){
      event.preventDefault(); 
      var q = $('.input-quantity input').val();
      if($(this).hasClass('plus')){
        q++;
      }else if($(this).hasClass('minus') && q>1){
        q--;
      }
      $('.input-quantity input').val(q);
    });

    //input enter
    $("#price_bottom").keypress(function(e){
      if (e.keyCode == 13) {
        price();
      }
    });
    $("#price_top").keypress(function(e){
      if (e.keyCode == 13) {
        price();
      }
    });
    $("#keyword").keypress(function(e){
      if (e.keyCode == 13) {
        keywords();
      }
    });




    //如果有分類params則找出指定分類
    if(location.search != ''){
      url = new URL(location.href);
      cat = url.searchParams.get("cat");
      subcat = url.searchParams.get("subcat");
      $('#selector .cat').click();
      $('#cat1-box-' + cat).click();
      if(subcat != '0'){
        setTimeout(function(){
          $('#cat2-box-'+subcat).click();
        },1000);
      }
    }

  }
});

//summernote function
function sendFile(object, file) {
  var data = new FormData;
  data.append('image[image]', file); // => params[:image][:image]
  data.append('image[content_type]', 'description'); // => params[:image][:content_type]

  $.ajax({
    data: data,
    type: 'POST',
    url: '/images', //=> create
    cache: false,
    contentType: false,
    processData: false,
    success: function(data) {
      //data => { id, url }
      var img = document.createElement('img');
      img.src = data.url;
      img.setAttribute('id', data.id);
      $(object).summernote('insertNode', img);
    }
  });
}

//summernote function
function deleteFile(image_id) {
  $.ajax({
    type: 'DELETE',
    url: '/images/' + image_id,
    cache: false,
    contentType: false,
    processData: false
  });
}

//click cat1_box
function cat1(object) {
  $("input[name='cat2_field[]']").remove();
  $("#tag_cat2 .bubble").remove();
  $('#cat2').slideDown(); //#cat2 slideDown

  tagName = $(object).data('name');
  tagId = $(object).data('id');

  if (tagName == $('#cat1_field').val()) {
    destroy($('#cat1-tag-' + tagId), 'cat1');
  } else {
    $('#cat1 div').css({ 'background-color': '#fff', 'color': '#000000' }); //復原全部cat1
    $(object).css({ 'background-color': '#403E4E', 'color': '#ffffff' });

    $('#cat1_field').val(tagName);

    $('#tag_cat1 .bubble').remove();
    tag_create(tagName, tagId, 'cat1');
  }

  $('#cat2_click').val('');
  form_submit();
}

//click cat2_box
function cat2(object) {
  tagId = $(object).data('id');
  tagName = $(object).data('name');
  tagCat1 = $(object).data('cat1');

  var onSelect = document.getElementById('cat2-input-' + tagId);

  if (onSelect === null) { //沒被選過 -> 選擇分類
    $(object).css({ 'background-color': '#9A9FB6', 'color': '#ffffff' });

    var input = document.createElement('input');
    input.type = 'hidden'
    input.name = 'cat2_field[]';
    input.value = tagId;
    input.id = 'cat2-input-' + tagId;
    document.getElementById('search_form').appendChild(input);

    tag_create(tagName, tagId, 'cat2');


  } else { //已被選過 -> 刪除分類
    destroy($('#cat2-tag-' + tagId), 'cat2');
  }
  $('#cat2_click').val('true');
  form_submit();
}

//新增tag
function tag_create(tagName, tagId, cat) {
  var selectBubble = document.createElement('div');
  var bubbleText = document.createTextNode(tagName + ' x'); //文字
  selectBubble.appendChild(bubbleText);
  selectBubble.id = cat + '-tag-' + tagId;
  selectBubble.className = 'bubble'; //class
  selectBubble.setAttribute('onclick', "destroy(this, '" + cat + "')");
  selectBubble.setAttribute('data-id', tagId);
  document.getElementById('tag_' + cat).appendChild(selectBubble);
}

//取消tag
function destroy(object, cat) {
  tagId = $(object).data('id');

  if (cat == 'cat1') { //cat1
    $('#cat1-box-' + tagId).css({ 'background-color': '#fff', 'color': '#000000' });
    $('#cat1-tag-' + tagId).remove();
    $('#cat1_field').val('');
    $('#tag_cat2 .bubble').each(function() {
      destroy(this, 'cat2');
    });
    $('#cat2').slideUp();

  } else if (cat == 'cat2') { //cat2
    $('#cat2-box-' + tagId).css({ 'background-color': '#fff', 'color': '#000000' });
    $('#cat2-tag-' + tagId).remove();
    $('#cat2-input-' + tagId).remove();

  } else if (cat == 'price') {
    $('#price-tag-p').remove();
    $('#price_bottom').val('');
    $('#price_top').val('');
  
  } else if (cat == 'keyword') {
    $('#keyword-tag-k').remove();
    $('#keyword').val('');
  }
  form_submit();
}

function clear_tag() {
  $('#price_bottom').val('');
  $('#price_top').val('');
  $('#price-tag-p').remove();
  $('#keyword').val('');
  $('#keyword-tag-k').remove();
  $('#tag_cat1 .bubble').each(function() {
    destroy(this, 'cat1');
  });
  $('#tag_cat2 .bubble').each(function() {
    destroy(this, 'cat2');
  });
  products_sort_by();
}

function form_submit() {
  $('#search_form').submit();
}

function keywords(){
  $('#keyword-tag-k').remove();
  tagName = $('#keyword').val();
  tag_create(tagName, 'k', 'keyword');

  fbq('track', 'Search', {
    search_string: tagName,
  });
  ga('send', 'pageview', '/search/'+tagName);
  form_submit();
}

function price() {
  $('#price-tag-p').remove();
  var pb = '';
  var pt = '';

  if ($('#price_bottom').val() != '') { //if有填寫
    pb = parseInt($('#price_bottom').val());
    if (!Number.isInteger(pb)) { //if填寫值不是int
      pb = '';
    }
  }

  if ($('#price_top').val() != '') {
    pt = parseInt($('#price_top').val());
    if (!Number.isInteger(pt)) {
      pt = '';
    }
  }

  if (Number.isInteger(pb) && Number.isInteger(pt)) { //if底>高
    if (pb > pt) {
      temp = pb;
      pb = pt;
      pt = temp;
    }
  }

  $('#price_bottom').val(pb);
  $('#price_top').val(pt);

  pb = pb.toLocaleString('en');
  pt = pt.toLocaleString('en');

  if (pb != '' && pt != '') {
    tagName = '$ ' + pb + ' ~ ' + pt;
  } else if (pb != '') {
    tagName = '$ ' + pb + ' ↑';
  } else if (pt != '') {
    tagName = '$ ' + pt + ' ↓';
  } else {
    return;
  }

  tag_create(tagName, 'p', 'price');
  form_submit();
}

function products_sort_by(){
  $('#sort_item').val($("#sort_by_item").val());
  $('#sort_order').val($("input[name=sequence]:checked").val());
  form_submit();
}

/*
  box/input/tag 屬性
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