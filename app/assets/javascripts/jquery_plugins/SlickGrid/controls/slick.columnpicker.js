(function($) {
  function SlickColumnPicker(columns,grid,options)
  {
    var $menu;
    var _self = this;   // Ekohe fork

    var defaults = {
      fadeSpeed: 250
    };

    function init() {
      grid.onHeaderContextMenu.subscribe(handleHeaderContextMenu);
        
      options = $.extend({}, defaults, options);

      $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:10250;' />").appendTo(document.body);

      $menu.bind("mouseleave", function(e) { $(this).fadeOut(options.fadeSpeed) });
      $menu.bind("click", updateColumn);
      
      // Ekohe fork
      // bind the column pick event
      $menu.bind("click", handleColumnPick);
      bindGrid();
      // ------------------------------------------------
    }
    
    // Ekohe fork
    // assign the picker itself to grid
    function bindGrid() {
      grid.picker = _self;
    }
    // --------------------------------------------------

    function handleHeaderContextMenu(e, args)
    {
      e.preventDefault();
      $menu.empty();

      var $li, $input, $allNoneInput;

      // Append "All/None" checkbox
      $li = $("<li />").appendTo($menu);
      $allNoneInput = $("<input type='checkbox' id='all_none' checked='checked' />").appendTo($li);
      $("<label for='all_none'>All/None</label>").appendTo($li);
      $("<hr/>").appendTo($menu);

      // Append columns checkbox
      for (var i=0; i<columns.length; i++) {
        $li = $("<li />").appendTo($menu);

        $input = $("<input type='checkbox' />")
                  .attr({id: "columnpicker_" + i, name: columns[i].field})
                  //.data("field", columns[i].field)
                  .appendTo($li);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked","checked");
        } else {
          $allNoneInput.removeAttr("checked");
        }

        $("<label for='columnpicker_" + i + "' />")
          .text(columns[i].name)
          .appendTo($li);
      }

      // Addpend "Force Fit Columns" checkbox
      $("<hr/>").appendTo($menu);
      $li = $("<li />").appendTo($menu);
      $input = $("<input type='checkbox' id='autoresize' />").appendTo($li);
      $("<label for='autoresize'>Force Fit Columns</label>").appendTo($li);
      if (grid.getOptions().forceFitColumns)
        $input.attr("checked", "checked");

      // Addpend "Synchronous Resizing" checkbox
      $li = $("<li />").appendTo($menu);
      $input = $("<input type='checkbox' id='syncresize' />").appendTo($li);
      $("<label for='syncresize'>Synchronous Resizing</label>").appendTo($li);
      if (grid.getOptions().syncColumnCellResize)
        $input.attr("checked", "checked");

      $menu
        .css("top", e.pageY - 10)
        .css("left", e.pageX - 10)
        .fadeIn(options.fadeSpeed);
    }
    
    function handleColumnPick(e, args) {
      _self.onColumnsPick.notify({});
    }

    function updateColumn(e) {
      var newWidths = {};
      var idColumns;

      $.each(grid.getColumns(), function(i, column){
        newWidths[column.id] = column.width;
      });

      $.each(columns, function(i, column){
        if (newWidths[column.id]) {
          columns[i].width = newWidths[column.id];
        }
      });

      // "Force Fit Columns" checkbox hanlder
      if (e.target.id == 'autoresize') {
        if (e.target.checked) {
          grid.setOptions({forceFitColumns: true});
          grid.autosizeColumns();
        } else {
          grid.setOptions({forceFitColumns: false});
        }
        return;
      }

      // "Synchronous Resizing" checkbox hanlder
      if (e.target.id == 'syncresize') {
        if (e.target.checked) {
          grid.setOptions({syncColumnCellResize: true});
        } else {
          grid.setOptions({syncColumnCellResize: false});
        }
        return;
      }

      // "All/None" checkbox hanlder
      if (e.target.id == 'all_none') {
        if (e.target.checked) {
          $menu.find(":checkbox[id^=columnpicker]").attr('checked', 'checked');
          grid.setColumns(columns);
        } else {
          $menu.find(":checkbox[id^=columnpicker]").not("[name='id']").removeAttr('checked');
          idColumns = $.grep(grid.getColumns(), function(n, i){
            return (n.field == 'id');
          });
          grid.setColumns(idColumns);
        }
        return;
      }

      // Column checkbox handler
      if ($(e.target).is(":checkbox")) {
        if ($menu.find(":checkbox:checked").length == 0) {
          $(e.target).attr("checked","checked");
          return;
        }

        var visibleColumns = [];
        $menu.find(":checkbox[id^=columnpicker]").each(function(i,e) {
          if ($(this).is(":checked")) {
            visibleColumns.push(columns[i]);
          }
        });
        grid.setColumns(visibleColumns);
      }
    }

    // Ekohe fork
    // define the columns pick event
    $.extend(this, {
      // Events
      "onColumnsPick":    new Slick.Event()
    });
    // ------------------------------------------

    init();
  }

  // Slick.Controls.ColumnPicker
  $.extend(true, window, { Slick: { Controls: { ColumnPicker: SlickColumnPicker }}});
})(jQuery);
