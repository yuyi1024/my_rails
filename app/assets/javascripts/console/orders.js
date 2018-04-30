$(document).on('turbolinks:load', function() {
  if (window.location.pathname.match(/orders/g)){
    
  }
});

function orderSearch(){
  event.preventDefault();
  $('#order_filter').submit();
}

function sort_by(){
  $('#sort_item').val($("#sort_by").val());
  $('#sort_order').val($("input[name=sequence]:checked").val());
  $('#order_filter').submit();
}

