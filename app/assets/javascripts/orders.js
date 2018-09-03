$(document).on('turbolinks:load', function() {
  if (load_path_shared_js(window.location.pathname, 'orders')){

    // 展開商品詳細
    $('h3.toggle').click(function(){
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

// 銀行帳號四位數字+空格
function bank_account(object){
  object.value = object.value.replace(/\s/g,'').replace(/\D/g,'').replace(/(\d{4})(?=\d)/g,"$1 ");
  //  \s    -> 空白字符
  //  \d    -> 數字
  //  n{X}  -> X個n
  //  ?=n   -> 後面緊接n的字串     
  //  $1    -> 第一個匹配的組($0~$9)                      
  //  replace(/(\d{4})(?=\d)/g,"$1 ") -> (連續4個數字)且(後面緊接數字)時，換成(第一組匹配的組 + ' ')
  //                                     ex.   12345 -> 把'1234'替換成'1234 '
}

// 選擇送貨方式(CVS/Home)後顯示對應付款方式
function selectShipMethod(m, process_id){
  var ship_method = document.getElementById('order_logistics_type').value;
  $.ajax({
    type: 'get',
    url: '/orders/ship_method/',
    data: { 
      ship_method: ship_method,
      location: m,
      process_id: process_id,
    },
  });
}

// 超商選擇(7-11/fami/hi-life)
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

// 開啟 ecpay 地圖
function chooseStore(){
  var st_type = $("input[name='store[]']:checked").val();
  var process_id = window.location.pathname.split('/')[2];
  // 開新子視窗執行 to_map，再由 to_map post 資料到 ecpay
  window.open('/orders/to_map?process_id=' + process_id + '&st_type=' + st_type);
}

// ecpay 地圖回傳
function callback(data){
  $('#store_' + data['stType']).next().next().next('.st_data').children('.st_id').text(data['stId']);
  $('#store_' + data['stType']).next().next().next('.st_data').children('.st_name').text(data['stName']);
  document.getElementById('store_' + data['stType']).checked = true;
  chooseType();
  store_required(data['stId'], data['stType']);
}

// 確認已選擇超商，可執行下步驟
function store_required(stId, stType){
  if(stId == ''){
    $('#order_logistics_subtype').val('');
    $('#order_receiver_store_id').val('');
    $('.submit_row').html('<p>請先選擇預送貨之超商</p>');
  }else{
    $('#order_logistics_subtype').val(stType);
    $('#order_receiver_store_id').val(stId);
    $('.submit_row').html('<input type="submit" name="commit" value="訂單建立" class="btn" onclick="pixel_and_ga();" data-disable-with="訂單建立">');
  }
}