$(document).on('turbolinks:load', function() {
  if (load_path_shared_js(window.location.pathname, 'messages')){
  
    // 展開答案
    $('.question').click(function(){
      $answer = $(this).next('.answer');
      if(!$answer.is(':visible')){
        $answer.slideDown();
        $(this).children('.glyphicon-triangle-left').css('transform', 'rotate(-90deg)');
        $(this).children('.glyphicon-triangle-right').css('transform', 'rotate(90deg)');
      }else{
        $answer.slideUp();
        $(this).children('.glyphicon').css('transform', 'rotate(0deg)');
      }
    });

  }
});

// 取的 user 的 email
function userEmail(email){
  if($('#message_reply_method').is(':checked')){
    $('#message_email').val(email);
  }else{
    $('#message_email').val('');
  }
}

