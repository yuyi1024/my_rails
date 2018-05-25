$(document).on('turbolinks:load', function() {
  if (load_path_shared_js(window.location.pathname, 'orders')){

    $('.product_list h3').click(function(){
      $list = $('.product_list .table')
      if(!$list.is(':visible')){
        $list.slideDown();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(-90deg)');
      }else{
        $list.slideUp();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(0deg)');
      }
      
    });
  }
});

//同會員資料
function getUserData(){
  $('#get_user_data').submit();
}

//new_order送貨方式選擇
function selectShipMethod(){
  var ship_method = document.getElementById('order_ship_method').value;
  $.ajax({
    type: 'get',
    url: '/orders/ship_method/',
    data : { ship_method: ship_method },
  });
}
