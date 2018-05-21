$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'users')){

    $('.role_change .panel-heading').click(function(){
      $body = $('.role_change .panel-body');
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
