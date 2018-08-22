$(document).on('turbolinks:load', function() {

  if (window.location.pathname == '/console'){
    ShowTime();
  }

  if (window.location.pathname.match(/console/g)){
    // 刪除選項展開
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

});

// 根據 path 載入對應 js
function load_path_console_js(path, str){
  if (path.match(new RegExp('console/'+str, 'g'))){
    return true;
  }else{
    return false;
  }
}

// index 搜尋結果排序
function sort_by(){
	$('#sort_item').val($("#sort_by").val());
  $('#sort_order').val($("input[name=sequence]:checked").val());
  $('#search_filter').submit();
}

// clear filter
function clearField(){
	event.preventDefault();
  $("#search_filter input").each(function(){
  	$type = $(this).attr('type');
  	
  	if($type == 'checkbox' || $type == 'radio'){
  		$(this).prop("checked", false);
  	}else if($type == 'text' || $type == 'date' || $type == 'number'){
  		$(this).val('');
  	}
  });
  if(document.getElementById("cat_box") != null){
  	document.getElementById("cat_box").selectedIndex = "0";
    $('#subcat_box').html("<option value='all'>所有次分類</option>");
  }
  if(document.getElementById("room") != null){
    document.getElementById("room").selectedIndex = "0";
  }
  $('#search_filter').submit();
}

// dashboard 顯示時間
function ShowTime(){
　document.getElementById('showbox').innerHTML = new Date().toLocaleString("ja-JP");
  setTimeout('ShowTime()',1000);
}