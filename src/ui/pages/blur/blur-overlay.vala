public class BlurOverlay : Gtk.Widget, Gtk.Buildable {
    private Gtk.Widget? _child = null;
    private Gtk.Widget? _overlay = null;
    
    private Graphene.Point card_position = { 10, 10 };
    private Graphene.Point? offset = null;
    
    public Gtk.Widget? child { get { return _child; }
        set {
            _child = value;
            _child.insert_after(this, null);
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
        
        var drag = new Gtk.GestureDrag();
        drag.drag_begin.connect((x, y) => {
            var widget = pick(x, y, Gtk.PickFlags.DEFAULT);
            
            if (widget == overlay) {
                offset = { card_position.x - (float) x, card_position.y - (float) y };
            }
        });
        
        drag.drag_update.connect((offset_x, offset_y) => {
            if (offset != null) {
                double x, y;
                drag.get_start_point(out x, out y);
                
                card_position.x = ((float) (x + offset_x) + offset.x).clamp(0, get_width() - overlay.get_width());
                card_position.y = ((float) (y + offset_y) + offset.y).clamp(0, get_height() - overlay.get_height());
                queue_allocate();
            }
        });
        
        add_controller(drag);
    }
    
    public override void snapshot(Gtk.Snapshot snapshot) {
        if (child != null && overlay != null) {
            var sn = new Gtk.Snapshot();
            snapshot_child(child, sn);
            var node = sn.free_to_node();
            snapshot.append_node(node);
            Graphene.Rect b;
            if (!overlay.compute_bounds(this, out b)) {
                b = Graphene.Rect().init(0, 0, 0, 0);
            }
            snapshot.push_blur(blur);
            snapshot.push_rounded_clip(Gsk.RoundedRect().init_from_rect(b, 20));
            snapshot.append_node(node);
            snapshot.pop();
            snapshot.pop();
            snapshot_child(overlay, snapshot);
        } else {
            if (child != null)
                snapshot_child(child, snapshot);
            if (overlay != null)
                snapshot_child(overlay, snapshot);
        }
        
        return;
    }
    
    public override void size_allocate(int width, int height, int baseline) {
        if (child != null) {
            child.allocate(get_width(), get_height(), 1, null);
        }
        
        Gtk.Requisition _, natural_size;
        overlay.get_preferred_size(out _, out natural_size);
        overlay.allocate(natural_size.width, natural_size.height, 0, new Gsk.Transform().translate(card_position));
    }
    
    public void add_child(Gtk.Builder builder, Object child, string? type) {
        var widget = child as Gtk.Widget;
        if (widget != null) {
            if (type == "overlay") {
                overlay = widget;
                return;
            } else if (type == null) {
                this.child = widget;
                return;
            }
        }
        
        base.add_child(builder, child, type);
    }
}