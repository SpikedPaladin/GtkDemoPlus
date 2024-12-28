[GtkTemplate (ui = "/me/paladin/Example/blur-page.ui")]
public class BlurPage : Adw.NavigationPage {
    [GtkChild]
    private unowned BlurOverlay blur_overlay;
}

public class BlurOverlay : Gtk.Widget {
    private Gtk.Box box;
    private Adw.Bin card;
    
    private Graphene.Point card_position = { 10, 10 };
    private Graphene.Point? offset = null;
    
    construct {
        overflow = Gtk.Overflow.HIDDEN;
        box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.add_css_class("blur");
        box.set_parent(this);
        card = new Adw.Bin() {
            css_classes = { "blur-card" },
            width_request = 200,
            height_request = 100
        };
        card.set_parent(this);
        
        var drag = new Gtk.GestureDrag();
        drag.drag_begin.connect((x, y) => {
            var widget = pick(x, y, Gtk.PickFlags.DEFAULT);
            
            if (widget == card) {
                offset = { card_position.x - (float) x, card_position.y - (float) y };
            }
        });
        
        drag.drag_update.connect((offset_x, offset_y) => {
            if (offset != null) {
                double x, y;
                drag.get_start_point(out x, out y);
                
                card_position.x = ((float) (x + offset_x) + offset.x).clamp(0, get_width() - card.get_width());
                card_position.y = ((float) (y + offset_y) + offset.y).clamp(0, get_height() - card.get_height());
                queue_allocate();
            }
        });
        
        add_controller(drag);
    }
    
    public override void snapshot(Gtk.Snapshot snapshot) {
        var sn = new Gtk.Snapshot();
        snapshot_child(box, sn);
        var node = sn.free_to_node();
        snapshot.append_node(node);
        Graphene.Rect b;
        if (!card.compute_bounds(this, out b)) {
            b = Graphene.Rect().init(0, 0, 0, 0);
        }
        snapshot.push_blur(5);
        snapshot.push_rounded_clip(Gsk.RoundedRect().init_from_rect(b, 20));
        snapshot.append_node(node);
        snapshot.pop();
        snapshot.pop();
        
        snapshot_child(card, snapshot);
        return;
    }
    
    public override void size_allocate(int width, int height, int baseline) {
        box.allocate(get_width(), get_height(), baseline, null);
        Gtk.Requisition _, natural_size;
        card.get_preferred_size(out _, out natural_size);
        card.allocate(natural_size.width, natural_size.height, baseline, new Gsk.Transform().translate(card_position));
    }
}