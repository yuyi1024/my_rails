$(document).on('turbolinks:load', function() {

});

function selectShip(){ //選擇送貨方式
	$user_data_chk = document.getElementById("user_data_chk");
	if($user_data_chk != null){
		$('#user_data').val($user_data_chk.checked);
	}
	$('#ship_form').submit();
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
