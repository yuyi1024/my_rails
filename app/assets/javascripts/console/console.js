$(document).on('turbolinks:load', function() {
  if (window.location.pathname.match(/console/g)){

    $('.delete .panel-heading').click(function(){
      $body = $('.delete .panel-body');
      if($body.is(':visible')){
        $body.slideUp();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(0deg)');
      }
      else{
        $body.slideDown();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(-90deg)');
      }
    });
  }
  if (window.location.pathname == '/console'){
    ShowTime();
  }
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
    $('#subcat_box').html("<option value='all'>所有次分類</option>");
  }
  $('#search_filter').submit();
}

function ShowTime(){
　document.getElementById('showbox').innerHTML = new Date().toLocaleString("ja-JP");
  setTimeout('ShowTime()',1000);
}
