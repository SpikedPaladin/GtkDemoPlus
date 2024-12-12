public class BlurWindow : Adw.Window {
    
    construct {
        content = new BlurOverlay();
    }
}

public class BlurOverlay : Gtk.Box {
    private Gtk.Box box;
    private Gtk.Button button;
    
    construct {
        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.append(button = new Gtk.Button.with_label("Hui"));
        append(box);
    }
    
    public override void snapshot(Gtk.Snapshot snapshot) {
        var child_snapshot = new Gtk.Snapshot();
        snapshot_child(box, child_snapshot);
        
        var main_widget_node = child_snapshot.free_to_node();
        
        Graphene.Rect bounds;
        if (!button.compute_bounds(box, out bounds)) {
            bounds = Graphene.Rect().init(0, 0, 0, 0);
        }
        
        snapshot.push_blur(5);
        snapshot.push_clip(bounds);
        
        snapshot.append_node(main_widget_node);
        
        snapshot.pop();
        snapshot.pop();
        
        Cairo.RectangleInt rect = { 0, 0, get_width(), get_height() };
        var clip = new Cairo.Region.rectangle(rect);
        
        rect.x = (int) Math.floor(bounds.origin.x);
        rect.y = (int) Math.floor(bounds.origin.y);
        
        rect.width = (int) Math.ceil(bounds.origin.x + bounds.size.width - rect.x);
        rect.width = (int) Math.ceil(bounds.origin.y + bounds.size.height - rect.y);
        clip.subtract_rectangle(rect);
        
        snapshot.push_clip(bounds);
        snapshot.append_node(main_widget_node);
        snapshot.pop();
        
        snapshot_child(box, snapshot);
    }
}