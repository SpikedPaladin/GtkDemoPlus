[GtkTemplate (ui = "/me/paladin/Example/transition-page.ui")]
public class TransitionPage : Adw.NavigationPage {
    
    construct {
        var widget = new DemoWidget();
        
        string[] color = {
            "red", "orange", "yellow", "green",
            "blue", "grey", "magenta", "lime",
            "yellow", "firebrick", "aqua", "purple",
            "tomato", "pink", "thistle", "maroon"
        };
        
        for (int i = 0; i < 16; i++) {
            var child = new DemoChild(color[i]);
            child.set_margin_start(4);
            child.set_margin_end(4);
            child.set_margin_top(4);
            child.set_margin_bottom(4);
            widget.add_child(child);
        }
        
        child = widget;
    }
}

public class DemoLayout : Gtk.LayoutManager {
    public float position;
    public int pos[16];
    
    construct {
        for (int i = 0; i < 16; i++)
            pos[i] = i;
    }
    
    public override Gtk.SizeRequestMode get_request_mode(Gtk.Widget widget) {
        return Gtk.SizeRequestMode.CONSTANT_SIZE;
    }
    
    public override void measure(Gtk.Widget widget, Gtk.Orientation orientation, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
        int minimum_size = 0;
        int natural_size = 0;
        
        for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
            int child_min = 0;
            int child_nat = 0;
            
            if (!child.should_layout())
                continue;
            
            child.measure(orientation, -1, out child_min, out child_nat, null, null);
            
            minimum_size = int.max(minimum_size, child_min);
            natural_size = int.max(natural_size, child_nat);
        }
        
        min = (int) (16 * minimum_size / Math.PI + minimum_size);
        pref = (int) (16 * natural_size / Math.PI + natural_size);
        min_base = -1;
        pref_base = -1;
    }
    
    public override void allocate(Gtk.Widget widget, int width, int height, int baseline) {
        int child_width = 0;
        int child_height = 0;
        
        for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
            if (!child.should_layout())
                continue;
            
            Gtk.Requisition child_req;
            child.get_preferred_size(out child_req, null);
            
            child_width = int.max(child_width, child_req.width);
            child_height = int.max(child_height, child_req.height);
        }
        
        int x0 = (int) (width / 2);
        int y0 = (int) (height / 2);
        
        float r = (float) (8 * child_width / Math.PI);
        
        int i = 0;
        float t = position;
        for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
            if (!child.should_layout())
                continue;
            
            float a = (float) (pos[i] * Math.PI / 8);
            
            Gtk.Requisition child_req;
            child.get_preferred_size(out child_req, null);
            
            int gx = (int) (x0 + (i % 4 - 2) * child_width);
            int gy = (int) (y0 + (i / 4 - 2) * child_height);
            
            int cx = (int) (x0 + Math.sin(a) * r - child_req.width / 2);
            int cy = (int) (y0 + Math.cos(a) * r - child_req.height / 2);
            
            int x = (int) (t * cx + (1 - t) * gx);
            int y = (int) (t * cy + (1 - t) * gy);
            
            child.allocate_size({x, y, child_width, child_height}, -1);
            
            i++;
        }
    }
    
    public void shufle() {
        int i, j, tmp;
        
        for (i = 0; i < 16; i++) {
            j = Random.int_range(0, i + 1);
            tmp = pos[i];
            pos[i] = pos[j];
            pos[j] = tmp;
        }
    }
}

public class DemoWidget : Gtk.Widget {
    public bool backward;
    public int64 start_time;
    public uint tick_id;
    
    private const float DURATION = 0.5F * TimeSpan.SECOND;
    
    static construct {
        set_layout_manager_type(typeof(DemoLayout));
    }
    
    construct {
        vexpand = true;
        
        var gesture = new Gtk.GestureClick();
        gesture.pressed.connect(clicked);
        add_controller(gesture);
    }
    
    public bool transition(Gtk.Widget widget, Gdk.FrameClock frame_clock) {
        var layout = (DemoLayout) get_layout_manager();
        var now = frame_clock.get_frame_time();
        
        queue_allocate();
        
        if (backward) {
            layout.position = (float) (1.0 - (now - start_time) / DURATION);
        } else {
            layout.position = (float) ((now - start_time) / DURATION);
        }
        
        if (now - start_time >= DURATION) {
            backward = !backward;
            layout.position = backward ? 1 : 0;
            /* keep things interesting by shuffling the positions */
            if (!backward)
                layout.shufle();
            tick_id = 0;

            return Source.REMOVE;
        }
        
        return Source.CONTINUE;
    }
    
    public void clicked() {
        if (tick_id != 0)
            return;
        
        var frame_clock = get_frame_clock();
        start_time = frame_clock.get_frame_time();
        tick_id = add_tick_callback(transition);
    }
    
    public override void dispose() {
        for (var child = get_first_child(); child != null; child = get_first_child()) {
            child.unparent();
        }
    }
    
    public void add_child(Gtk.Widget widget) {
        widget.set_parent(this);
    }
}

public class DemoChild : Gtk.Widget {
    public Gdk.RGBA color;
    
    public DemoChild(string color) {
        var rgba = Gdk.RGBA();
        rgba.parse(color);
        this.color = rgba;
    }
    
    protected override void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
        min = pref = 32;
        min_base = -1;
        pref_base = -1;
    }
    
    public override void snapshot(Gtk.Snapshot snapshot) {
        base.snapshot(snapshot);
        
        snapshot.append_color(color, Graphene.Rect().init(0, 0, get_width(), get_height()));
    }
}