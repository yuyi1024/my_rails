$(document).on('turbolinks:load', function() {
	//會員中心
	$('.nav-tabs li').click(function(){
		$('.nav-tabs li').each(function(){
			$(this).removeClass("active");	
		});
		$(this).addClass("active");	
	});

});

function editData(object){
  $input = $(object).parent().prev('input');
  $input.removeAttr("disabled");
  $input.css('background-color', '#fff');
  $(object).replaceWith("<input type='submit' name='commit' value='儲存' data-disable-with='儲存' class='btn save'>");
}