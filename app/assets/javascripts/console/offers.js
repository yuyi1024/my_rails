$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'offers')){
    
    // 將選擇的免運選項(全部、CVS、Home)存入 hidden_field
    $("input[name='freight[]']").change(function(){
      var arr = [];
      if($('#freight_CVS').is(':checked')){
        arr.push('CVS'); 
      }
      if($('#freight_Home').is(':checked')){
        arr.push('Home');
      }
      if(arr.length != 1 ){
        freight = 'all';
      }else{
        freight = arr[0];
      }
      $('#offer_offer_freight').val(freight);
    });
  }
});

// 選擇作用範圍(全館、金額、商品)，顯示範圍設定
function select_range(){
  var range = $('#offer_range').val();
  $.ajax({
    type: 'GET',
    url: '/console/offers/select_range',
    data : { range: range },
  });
}

// 選擇優惠內容(免運、打折、折金額)，顯示優惠設定
function select_offer(){
  var offer = $('#offer_offer').val();
  $('#offer_offer_freight').val();
  
  if(offer == 'freight'){
    $('#offer_condition').html("<div id='offer_condition'><input type='checkbox' name='freight[]' id='freight_CVS' value='CVS' checked><label for='freight_CVS'>超商取貨</label><br><input type='checkbox' name='freight[]' id='freight_Home' value='Home' ' checked><label for='freight_Home'>宅配</label></div>");
    $('#offer_offer_freight').val('all');
  }else if(offer == 'price'){
    $('#offer_condition').html("折扣<input value='200' type='number' name='offer[offer_price]' id='offer_offer_price'>元");
    
  }else if(offer == 'discount'){
    $('#offer_condition').html("打<input value='85' type='number' name='offer[offer_discount]' id='offer_offer_discount'>折");
  }
}



