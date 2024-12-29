public class BlurOverlay : Gtk.Widget, Gtk.Buildable {
    private Gtk.Widget? _main_widget = null;
    private Gtk.Widget? _overlay = null;
    
    public Gtk.Widget? main_widget { get { return _main_widget; }
        set {
            if (_main_widget != null)
                _main_widget.unparent();
            
            _main_widget = value;
            _main_widget.insert_after(this, null);
        }
    }
    public Gtk.Widget? overlay { get { return _overlay; }
        set {
            _overlay = value;
            _overlay.insert_before(this, null);
        }
    }
    
    private double _blur = 5;
    public double blur { get { return _blur; }
        set {
            _blur = value;
            queue_draw();
        }
    }
    
    construct {
        overflow = Gtk.Overflow.HIDDEN;
    }
    
    public override void snapshot(Gtk.Snapshot snapshot) {
        if (main_widget != null && overlay != null) {
            var child_snapshot = new Gtk.Snapshot();
            snapshot_child(main_widget, child_snapshot);
            var node = child_snapshot.free_to_node();
            snapshot.append_node(node);
            Graphene.Rect bounds;
            if (!overlay.compute_bounds(this, out bounds)) {
                bounds = Graphene.Rect().init(0, 0, 0, 0);
            }
            snapshot.push_blur(blur);
            
            snapshot.push_clip(bounds);
            snapshot.append_node(node);
            snapshot.pop();
            snapshot.pop();
            snapshot_child(overlay, snapshot);
        } else {
            if (main_widget != null)
                snapshot_child(main_widget, snapshot);
            if (overlay != null)
                snapshot_child(overlay, snapshot);
        }
        
        return;
    }
    
    public override void size_allocate(int width, int height, int baseline) {
        if (main_widget != null && main_widget.visible) {
            main_widget.allocate(get_width(), get_height(), 1, null);
        }
        
        Gtk.Requisition _, natural_size;
        overlay.get_preferred_size(out _, out natural_size);
        overlay.allocate(get_width(), natural_size.height, 0, null);
    }
    
    public void add_child(Gtk.Builder builder, Object child, string? type) {
        var widget = child as Gtk.Widget;
        if (widget != null) {
            if (type == "overlay") {
                overlay = widget;
                return;
            } else if (type == null) {
                this.main_widget = widget;
                return;
            }
        }
        
        base.add_child(builder, child, type);
    }
}