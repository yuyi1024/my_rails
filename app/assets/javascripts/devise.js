$(document).on('turbolinks:load', function() {

});

// 修改會員資料的 input 取消 disable
function editData(object){
  $input = $(object).parent().prev('input');
  $input.removeAttr("disabled");
  $input.css('background-color', '#fff');
  $(object).replaceWith("<input type='submit' name='commit' value='儲存' class='btn save'>");
}

// 訂單列表選擇status
function orderStatusSelect(){
	var status = document.getElementById("order_status").value;

	$.ajax({
		type: 'get',
		url: '/user/order_status_select',
		data: {
			status: status,
		},
	});
}