$(document).on('turbolinks:load', function() {

});

function load_path_console_js(path, str){
  if (path.match(new RegExp('console/'+str, 'g'))){
    return true;
  }else{
    return false;
  }
}

function sort_by(){
	$('#sort_item').val($("#sort_by").val());
  $('#sort_order').val($("input[name=sequence]:checked").val());
  $('#search_filter').submit();
}

function clearField(){
	event.preventDefault();
  $("#search_filter input").each(function(){
  	$type = $(this).attr('type');
  	
  	if($type == 'checkbox' || $type == 'radio'){
  		$(this).prop("checked", false);
  	}else if($type == 'text' || $type == 'date'){
  		$(this).val('');
  	}
  });
  if(document.getElementById("cat_box") != null){
  	document.getElementById("cat_box").selectedIndex = "0";
  	document.getElementById("subcat_box").selectedIndex = "0";
  }
  $('#search_filter').submit();
}
