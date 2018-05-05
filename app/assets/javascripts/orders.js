$(document).on('turbolinks:load', function() {

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
