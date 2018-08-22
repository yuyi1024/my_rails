$(document).on('turbolinks:load', function() {
	
});

// 增加欄位(新增次分類)
function add_subcat_column(){
  event.preventDefault();
  $('.add_column').append('<input type="text" name="subcat_field[]" id="cat_field_" class="col-sm-4 col-sm-offset-4" required="required">');
}

// 新增分類 submit
function add_cat_submit(){
  event.preventDefault();
  var cat;
  var subcat = [];
  
  // 若主分類 text_field 有值則採用，否則用 select_box 的 value
  if($('#cat_field').val() == ''){
    cat = document.getElementById('add_cat_box').value;
  }else{
    cat = $('#cat_field').val();
  }

  // 檢查次分類 text_field 是否有重複值
  $("input[name='subcat_field[]']").each(function(){
    if($(this).val() != ''){
    	same = false;
    	
    	for(var i = 0; i < subcat.length; i++){
    		if($(this).val() == subcat[i]){
    			same = true;
    		}
    	} 
      if(same == false){
      	subcat.push($(this).val());
      }
    }
  });

  $.ajax({
    type: 'POST',
    url: '/console/categories',
    data : {
      cat: cat,
      subcat: subcat
    },
  });
}
