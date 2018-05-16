if (window.location.pathname.match(/orders/g)){

  $(document).on('turbolinks:load', function() {

  });

  function orderSearch(){
    event.preventDefault();
    $('#order_filter').submit();
  }

  function clearField(){
  	event.preventDefault();
    $("#order_filter input").each(function(){
    	$type = $(this).attr('type');
    	if($type == 'checkbox'){
    		$(this).prop("checked", false);
    	}else if($type == 'text' || $type == 'date'){
    		$(this).val('');
    	}
    });
    $('#order_filter').submit();
  }

  function sort_by(){
  	$('#sort_item').val($("#sort_by").val());
    $('#sort_order').val($("input[name=sequence]:checked").val());
    $('#order_filter').submit();
  }


}