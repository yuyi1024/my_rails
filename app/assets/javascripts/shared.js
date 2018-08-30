$(document).on('turbolinks:load', function() {
  //回頁頂
  $('#to_top').click(function(){
    $('html, body').animate({
      scrollTop: 0
    }, 100);
  });
});

// 按分頁 window 會回商品第一列
function to_top(){
  $('html, body').animate({
      scrollTop: $("#tag").offset().top
  }, 100);
  // offset(返回第一個匹配元素的偏移座標) 
}

// flash alert & success
function message_notify(type, msg){
  if(type == 'danger'){
    $.notify({
      icon: 'glyphicon glyphicon-exclamation-sign',
      message: msg,
    },{
      type: type,
      delay: '0',
    });
  }else if(type == 'success'){
    $.notify({
      icon: 'glyphicon glyphicon-glyphicon-ok',
      message: msg,
    },{
      type: type,
      delay: '2000',
    });
  }

}

function openCart(){
  $('#sidebar_cart').animate({left:'0px'});
  $('.mask').css('display', 'block');
  $('body').css('overflow', 'hidden');
}

function closeCart(){
  $('#sidebar_cart').animate({left:'-350px'});
  $('.mask').css('display', 'none');
  $('body').css('overflow', 'visible');
}

function change_item_quantity(object){
  item_id = object.id.split("-")[1];
  item_quantity = object.value;

  $.ajax({
    type: 'POST',
    url: '/carts/change/' + item_id,
    data : { quantity: item_quantity },
  });
}


function load_path_shared_js(path, str){
  if (path.match(new RegExp(str, 'g')) && path.match(/console/g) == null){
    return true;
  }else{
    return false;
  }
}
