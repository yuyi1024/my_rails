$(document).on('turbolinks:load', function() {
	if($('#store_value').text() != ''){
		document.getElementById("in_store").checked = true;
		$('#ship_form').submit();
	}
});

function selectStore(){ //選擇超商
	$('#ezship_form').submit();
}

function selectShip(){ //選擇送貨方式
	$('#ship_form').submit();
}

function order_submit(){ //確認下單
	var ship_method = document.querySelector('input[name="ship_method"]:checked').value;
	$('#order_ship_method').val(ship_method);
	if(ship_method == 'in_store'){
		$('#order_address').val($('#store_value').text());
	}
	$('#order_pay_method').val(document.querySelector('input[name="pay_method"]:checked').value);
}


