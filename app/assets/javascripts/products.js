$(document).on('turbolinks:load', function() {

  var cat1_tag = '';
  var cat2_tag = '';
  var price_bottom = 0;
  var price_up = 0;
  
  $('#selector .col-sm-3').click(function(){
    $target = $($(this).data('target'));

    if(!$target.is(':visible')){
      $('#boxes').children().each(function(){
        $(this).slideUp();
      });
      $target.slideDown('slow');
    }else{
      $target.toggle('slow');
    }
    
  });

  




});

function cat1(object){
  $target2 = $($(object).data('target'));
  $target2.slideDown();
  $('#cat1_field').val($(object).text());
  $('#cat2_field').val('');
  $('#search_form').submit();
}

function cat2(object){
  $('#cat2_field').val($(object).text());
  $('#search_form').submit();
}

function search(){
  $('#search_form').submit();
}



