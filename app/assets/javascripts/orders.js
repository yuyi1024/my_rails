$(document).on('turbolinks:load', function() {
  if (load_path_shared_js(window.location.pathname, 'orders')){

    $('.product_list h3').click(function(){
      $list = $('.product_list .table')
      if(!$list.is(':visible')){
        $list.slideDown();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(-90deg)');
      }else{
        $list.slideUp();
        $('span.glyphicon-chevron-left').css('transform', 'rotate(0deg)');
      }
      
    });
  }
});

//new_order送貨方式選擇
function selectShipMethod(){
  var ship_method = document.getElementById('order_ship_method').value;
  $.ajax({
    type: 'get',
    url: '/orders/ship_method/',
    data : { ship_method: ship_method },
  });
}



//////////////////

function chooseType(){
  var stId = '';
  var stType = '';

  $("input[name='store[]']").each(function(){
    $(this).next().next('.select').html('');
    
    if($(this).is(':checked')){
      $(this).next().next('.select').html('<span class="glyphicon glyphicon-search"></span>選擇超商');
      
      $st_id = $(this).next().next().next('.st_data').children('.st_id');
      if($st_id.text() != ''){
        stId = $st_id.text();
        stType = $(this).val();
      }  
    }
  });
  store_required(stId, stType);
}

function chooseStore(){
  var st_type = $("input[name='store[]']:checked").val();
  var process_id = window.location.pathname.split('/')[2];
  window.open('/orders/to_map?process_id=' + process_id + '&st_type=' + st_type);
}

function callback(data){
  $('#store_' + data['stType']).next().next().next('.st_data').children('.st_id').text(data['stId']);
  $('#store_' + data['stType']).next().next().next('.st_data').children('.st_name').text(data['stName']);
  document.getElementById('store_' + data['stType']).checked = true;
  chooseType();
  store_required(data['stId'], data['stType']);
}

function store_required(stId, stType){
  if(stId == ''){
    $('#order_address').val('');
    $('.submit_row').html('<p>請先選擇預送貨之超商</p>');
  }else{
    $('#order_address').val(stId + '-' + stType);
    $('.submit_row').html('<input type="submit" name="commit" value="訂單建立" class="btn" data-disable-with="訂單建立">');
  }
}




