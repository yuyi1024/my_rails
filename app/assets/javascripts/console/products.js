$(document).on('turbolinks:load', function() {
  if (load_path_console_js(window.location.pathname, 'products')){

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

  }
});

//summernote function
function sendFile(object, file) {
  var data = new FormData;
  data.append('image[image]', file); // => params[:image][:image]
  data.append('image[content_type]', 'description'); // => params[:image][:content_type]

  $.ajax({
    data: data,
    type: 'POST',
    url: '/images', //=> create
    cache: false,
    contentType: false,
    processData: false,
    success: function(data) {
      //data => { id, url }
      var img = document.createElement('img');
      img.src = data.url;
      img.setAttribute('id', data.id);
      $(object).summernote('insertNode', img);
    }
  });
}

//summernote function
function deleteFile(image_id) {
  $.ajax({
    type: 'DELETE',
    url: '/images/' + image_id,
    cache: false,
    contentType: false,
    processData: false
  });
}

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

//Jcrop
function showCoords(c) {
  $('#product_crop_x').val(c.x);
  $('#product_crop_y').val(c.y);
  $('#product_crop_w').val(c.w);
  $('#product_crop_h').val(c.h);
}
