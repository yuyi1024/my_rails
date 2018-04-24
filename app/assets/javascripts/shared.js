$(document).on('turbolinks:load', function() {

});

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
