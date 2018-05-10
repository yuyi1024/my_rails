$(document).on('turbolinks:load', function() {
  if (window.location.pathname.match(/products/g)){

  }
});

function cat_select(){
	var cat = document.getElementById('cat_box').value;
	$.ajax({
    type: 'GET',
    url: '/console/products',
    data : { cat: cat },
  });
}

function clearField(){
	event.preventDefault();
  $("#product_filter input").each(function(){
  	$type = $(this).attr('type');
  	if($type == 'checkbox'){
  		$(this).prop("checked", false);
  	}else if($type == 'text' || $type == 'date'){
  		$(this).val('');
  	}
  });
  document.getElementById("cat_box").selectedIndex = "0";
  document.getElementById("subcat_box").selectedIndex = "0";
  $('#product_filter').submit();
}

function sort_by(){
	$('#sort_item').val($("#sort_by").val());
  $('#sort_order').val($("input[name=sequence]:checked").val());
  $('#product_filter').submit();
}