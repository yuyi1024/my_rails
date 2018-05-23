$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'messages')){

  }
});

function messageSearch(){
  $('#search_filter').submit();
}