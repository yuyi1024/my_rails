$(document).on('turbolinks:load', function() {
  if (window.location.pathname.match(/orders/g)){
    
  }
});

function orderSearch(){
  event.preventDefault();
  $('#order_filter').submit();
}