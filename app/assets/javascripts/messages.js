$(document).on('turbolinks:load', function() {
  if (load_path_shared_js(window.location.pathname, 'messages')){
  
    $('.question').click(function(){
      $answer = $(this).next('.answer');
      if(!$answer.is(':visible')){
        $answer.slideDown();
        $(this).children('.glyphicon-triangle-left').css('transform', 'rotate(-90deg)');
      }else{
        $answer.slideUp();
        $(this).children('.glyphicon-triangle-left').css('transform', 'rotate(0deg)');
      }
    });
  }
});
