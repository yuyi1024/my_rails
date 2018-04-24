$(document).on('turbolinks:load', function() {

	//若 EZship 有回傳值，即選擇超商取貨 radio
	if($('#store_value').text() != ''){
		document.getElementById("in_store").checked = true;
		$('#ship_form').submit();
	}

});

function selectStore(){ //選擇超商
	$('#ezship_form').submit();
}

function selectShip(){ //選擇送貨方式
	$user_data_chk = document.getElementById("user_data_chk");
	if($user_data_chk != null){
		$('#user_data').val($user_data_chk.checked);
	}
	$('#ship_form').submit();
}

function order_submit(){ //確認下單
	var pay_method = document.querySelector('input[name="pay_method"]:checked');
	var ship_method = document.querySelector('input[name="ship_method"]:checked');

	if(pay_method != null && ship_method != null){
		$('#order_pay_method').val(pay_method.value);
		$('#order_ship_method').val(ship_method.value);
		
		if(ship_method.value == 'in_store'){
			if($('#store_value').text() == ''){
				alert('未選擇超商');
			}else{
				$('#order_address').val($('#store_value').text());
				if (form_required()){
					$('#new_order').submit();
				}
			}
		}else if(ship_method.value == 'to_address'){
			if (form_required()){
				$('#new_order').submit();
			}
		}		

	}else{
		alert('送貨或付款方式未填寫');
	}
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
