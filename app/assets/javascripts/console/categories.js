$(document).on('turbolinks:load', function() {
	
});

function add_subcat_column(){
  event.preventDefault();
  $('.add_column').append('<input type="text" name="subcat_field[]" id="cat_field_" class="col-sm-4 col-sm-offset-4" required="required">');
}

function add_cat_submit(){
  event.preventDefault();
  var cat;
  var subcat = [];
  console.log('ddd');
  
  if($('#cat_field').val() == ''){
    cat = document.getElementById('add_cat_box').value;
  }else{
    cat = $('#cat_field').val();
  }

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
