$(document).on('turbolinks:load', function() {

	//若 EZship 有回傳值，即選擇超商取貨 radio
	if($('#store_value').text() != ''){
		document.getElementById("in_store").checked = true;
		$('#ship_form').submit();
	}

});

function selectShip(){ //選擇送貨方式
	$user_data_chk = document.getElementById("user_data_chk");
	if($user_data_chk != null){
		$('#user_data').val($user_data_chk.checked);
	}
	$('#ship_form').submit();
}


function form_required(){
	var required = true;
	$('#new_order .row input').each(function(){
		if($(this).val() == ''){
			required = false;
			alert($(this).prev().text()+'尚未填寫');
		}
	});
	return required;
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
