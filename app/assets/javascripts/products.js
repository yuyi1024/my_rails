$(document).on('turbolinks:load', function() {
  
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

  $('#cat1 .col-sm-1').click(function(){
    $target2 = $($(this).data('target'));
    $target2.slideDown();
    $('#cat1_field').val($(this).text());
    $('#search_form').submit();
  });

});

function cat2(object){
  $('#cat2_field').val($(object).text());
  console.log($('#cat2_field').val());
  $('#search_form').submit();
}

function search(){
  console.log($('#cat1_field').val());
  console.log($('#cat2_field').val());
  console.log($('#price_bottom').val());
  console.log($('#price_top').val());
}



