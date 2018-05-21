$(document).on('turbolinks:load', function() {

});

function editData(object){
  $input = $(object).parent().prev('input');
  $input.removeAttr("disabled");
  $input.css('background-color', '#fff');
  $(object).replaceWith("<input type='submit' name='commit' value='儲存' data-disable-with='儲存' class='btn save'>");
}