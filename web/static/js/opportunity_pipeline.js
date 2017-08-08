export var Pipeline = {
  start: function(){
    $( '.column' ).sortable({
      connectWith: ['.column', '.column_status'],
      handle: '.portlet-content',
      cancel: '.portlet-toggle',
      start: function (event, ui) {
        ui.item.addClass('tilt');
      },
      stop: function (event, ui) {
        ui.item.removeClass('tilt');
      },
      receive: function (event, ui) {
        var id = $(ui.item).data('id');
        var column = ui.item.parent()[0];
        var stage = $(column).data('id');
        if (stage === 'lost')
        {
          $(ui.item).remove();
          $.ajax({
            data: {card : {status: 2}},
            type: 'PUT',
            url: '/api/v2/card/'+ id
          });
        } else if (stage === 'delete'){
          $(ui.item).remove();
          $.ajax({
            type: 'DELETE',
            headers: {'Authorization': 'Bearer '+jwtToken},
            url: '/api/v2/card/'+ id
          });
        } else if (stage === 'win'){
          $(ui.item).remove();
          $.ajax({
            data: {card : {status: 1}},
            type: 'PUT',
            headers: {'Authorization': 'Bearer '+jwtToken},
            url: '/api/v2/card/'+ id
          });
        }else{
          $.ajax({
            data: {card : {board_column_id: stage}},
            type: 'PUT',
            headers: {'Authorization': 'Bearer '+jwtToken},
            url: '/api/v2/card/'+ id,
            complete: function(response) {
              console.log(response);
              let newCard = response.responseJSON.data.board_column.name.trim();
              console.log(newCard);
              if(newCard == "Lead in") {
              alert("Please send the following link to the customer: http://m.me/589019314615856");
            }}
          });
        }
      }
    });

    $( '.portlet' )
      .addClass( 'ui-widget ui-widget-content ui-helper-clearfix ui-corner-all' )
      .find( '.portlet-header' )
        .addClass( 'ui-widget-header ui-corner-all' );
  },

  stop: function() {
    $( '.column' ).sortable('destroy');
  }
};
