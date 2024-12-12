[GtkTemplate (ui = "/me/paladin/Example/reorderable-page.ui")]
public class ReorderablePage : Adw.Window {
    [GtkChild]
    private unowned Gtk.ListBox list;
    private ListStore store = new ListStore(typeof(TestItem));
    
    public class TestItem : Object {
        public string title { get; set; }
        public string subtitle { get; set; }
    }
    
    construct {
        store.append(new TestItem() { title = "Some", subtitle = "Other" });
        store.append(new TestItem() { title = "Some 2", subtitle = "Other 2" });
        
        var drop_target = new Gtk.DropTarget(typeof (ReorderableItem), Gdk.DragAction.MOVE);
        
        var iter = settings.get_value("list-items").iterator();
        
        string title, subtitle;
        while (iter.next("(ss)", out title, out subtitle)) {
            list.append(new ReorderableItem() {
                title = title,
                subtitle = subtitle
            });
        }
        
        list.add_controller(drop_target);
        
        for (int i = 0; list.get_row_at_index(i) != null; i++) {
            var row = list.get_row_at_index(i) as ReorderableItem;
            
            double drag_x = 0.0;
            double drag_y = 0.0;
            
            var drop_controller = new Gtk.DropControllerMotion();
            var drag_source = new Gtk.DragSource() {
                actions = Gdk.DragAction.MOVE
            };
            
            row.add_controller(drag_source);
            row.add_controller(drop_controller);
            
            // Drag handling
            drag_source.prepare.connect((x, y) => {
                drag_x = x;
                drag_y = y;
                
                Value value = Value(typeof (ReorderableItem));
                value.set_object(row);
                
                return new Gdk.ContentProvider.for_value(value);
            });
            
            drag_source.drag_begin.connect((drag) => {
                var drag_widget = new Gtk.ListBox();
                
                drag_widget.set_size_request(row.get_width(), row.get_height());
                drag_widget.add_css_class("boxed-list");
                
                var drag_row = new ReorderableItem() {
                    title = row.get_title()
                };
                
                drag_row.add_prefix(new Gtk.Image.from_icon_name("list-drag-handle-symbolic") {
                    css_classes = { "dim-label" }
                });
                
                drag_widget.append(drag_row);
                drag_widget.drag_highlight_row(drag_row);
                
                var icon = Gtk.DragIcon.get_for_drag(drag) as Gtk.DragIcon;
                icon.child = drag_widget;
                
                drag.set_hotspot((int) drag_x, (int) drag_y);
            });
            
            // Update row visuals during DnD operation
            drop_controller.enter.connect(() => list.drag_highlight_row(row));
            drop_controller.leave.connect(() => list.drag_unhighlight_row());
        }
        
        // Drop Handling
        drop_target.drop.connect((drop, value, x, y) => {
            var value_row = value.get_object() as ReorderableItem ? ;
            Gtk.ListBoxRow? target_row = list.get_row_at_y((int) y);
            // If value or the target row is null, do not accept the drop
            if (value_row == null || target_row == null) {
                return false;
            }
            
            int target_index = target_row.get_index();
            
            list.remove(value_row);
            list.insert(value_row, target_index);
            target_row.set_state_flags(Gtk.StateFlags.NORMAL, true);
            
            return true;
        });
    }
    
    [GtkCallback]
    private void on_add_clicked() {
        var dialog = new AddItemDialog();
        dialog.add.connect((new_title, new_subtitle) => {
            var val = settings.get_value("list-items");
            var iter = val.iterator();
            
            var builder = new VariantBuilder(val.get_type());
            string title, subtitle;
            while (iter.next("(ss)", out title, out subtitle)) {
                builder.add("(ss)", title, subtitle);
            }
            builder.add("(ss)", new_title, new_subtitle);
            settings.set_value("list-items", builder.end());
        });
        
        dialog.present(this);
    }
}