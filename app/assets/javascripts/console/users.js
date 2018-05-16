if (window.location.pathname.match(/users/g)){
  
  $(document).on('turbolinks:load', function() {
    
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
    
  });

  
  function sort_by(){
    $('#sort_item').val($("#sort_by").val());
    $('#sort_order').val($("input[name=sequence]:checked").val());
    $('#user_filter').submit();
  }

  function clearField(){
    event.preventDefault();
    $("#user_filter input").each(function(){
      $type = $(this).attr('type');
      if($type == 'checkbox' || $type == 'radio'){
        $(this).prop("checked", false);
      }else if($type == 'text'){
        $(this).val('');
      }
    });
    $('#user_filter').submit();
  }


}
