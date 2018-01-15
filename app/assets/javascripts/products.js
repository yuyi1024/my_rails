$(document).on('turbolinks:load', function() {
  
  $('#selector .col-sm-3').click(function(){
    $target = $($(this).data('target'));
    $target.toggle();
  });

  $('#cat1 .col-sm-3').click(function(){
    $target = $($(this).data('target'));
    // if($target.is(':visible')){
      
    // }

    $target.toggle();


    $('#cat1_field').val($(this).text());
    $('#search_form').submit();
  });

 




  // $('.search .col-sm-3').click(function(){
  //   $target = $($(this).data('target'))
  //   $('.collection .col-sm-12').slideUp();
  //   if(!$target.is(":visible")){
  //     $target.slideDown();
  //   }
  // });
    
});



