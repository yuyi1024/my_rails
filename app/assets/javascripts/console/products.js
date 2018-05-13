if (window.location.pathname.match(/products/g)){
  
  $(document).on('turbolinks:load', function() {
    $('#summernote').summernote({
      height: '400px',
      placeholder: '為商品新增描述...',
      lang: 'zh-TW',
      toolbar: [
        ['para', ['style']],
        ['style', ['bold', 'italic', 'underline', 'strikethrough', 'clear']],
        ['fontsize', ['fontsize']],
        ['color', ['color']],
        ['para', ['ul', 'ol', 'paragraph']],
        ['insert', ['table', 'hr']],
        ['insert', ['link', 'picture']],
        ['misk', ['codeview']],
      ],
      callbacks: {
        onImageUpload: function(files) {
          sendFile(this, files[0]);
          //this => $('#summernote')
          //file => FileList{ 0: File(xxxx), length: 1 }
          //file[0] => File(xxxx){ name, size, type...... }
        },
        onMediaDelete: function(target, editor, editable) {
          //target => { 0:img#id, context, length }

          var image_id = target[0].id;
          deleteFile(image_id);
          target.remove();
        }
      }
    });

    $('#cropbox').Jcrop({
      aspectRatio: 1,
      setSelect: [0, 0, 1000, 1000],
      boxWidth: 600,
      onSelect: showCoords,
      onChange: showCoords,
    });

    $('.delete .panel-heading').click(function(){
      $body = $('.delete .panel-body');
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

  function cat_select(m){
    var cat = document.getElementById('cat_box').value;
    $('#product_category_id').val(cat);

    $.ajax({
      type: 'GET',
      url: '/console/products/get_subcat',
      data : { 
        cat: cat,
        method: m
      },
    });
  }

  function subcat_select(){
    var subcat = document.getElementById('subcat_box').value;
    $('#product_subcategory_id').val(subcat);
  }


  function clearField(){
    event.preventDefault();
    $("#product_filter input").each(function(){
      $type = $(this).attr('type');
      if($type == 'checkbox'){
        $(this).prop("checked", false);
      }else if($type == 'text' || $type == 'date'){
        $(this).val('');
      }
    });
    document.getElementById("cat_box").selectedIndex = "0";
    document.getElementById("subcat_box").selectedIndex = "0";
    $('#product_filter').submit();
  }

  function sort_by(){
    $('#sort_item').val($("#sort_by").val());
    $('#sort_order').val($("input[name=sequence]:checked").val());
    $('#product_filter').submit();
  }

  //Jcrop
  function showCoords(c) {
    $('#product_crop_x').val(c.x);
    $('#product_crop_y').val(c.y);
    $('#product_crop_w').val(c.w);
    $('#product_crop_h').val(c.h);
  }

}
