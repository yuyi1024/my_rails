//開關購物車在 shared.js
$(document).on('turbolinks:load', function() {

});

function selectShipMethod(){
	var ship_method = document.getElementById('order_ship_method').value;
	$.ajax({
    type: 'get',
    url: '/carts/ship_method/',
    data : { ship_method: ship_method },
  });
	// var ship_method = document.getElementById('order_ship_method').value;
	// var freight = parseInt($('#in_store').text());
	// var subtotal = parseInt($('#subtotal').text());

	// if(ship_method == 'pickup_and_cash'){
	// 	$('#order_pay_method').html("<option value='pickup_and_cash'>超商取貨付款</option>");
	// }else{
	// 	if(ship_method == 'home_delivery'){
	// 		freight = parseInt($('#home_delivery').text());
	// 	}
	// 	$('#order_pay_method').html("<option value='cash_card'>信用卡</option><option value='atm'>實體ATM</option>");
	// }

	// var total = subtotal + freight;
	// $('#freight').text('$ ' + freight);
	// $('#total').text('$ ' + total);
}
