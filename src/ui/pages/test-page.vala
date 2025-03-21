[GtkTemplate (ui = "/me/paladin/Example/test-page.ui")]
public class TestPage : Adw.NavigationPage {}

private bool approx_value(double a, double b, double epsilon) {
    return (((a) > (b) ? (a) - (b) : (b) - (a)) < (epsilon));
}

public class ReorderableList : Gtk.Widget, Gtk.Buildable {
    private Gtk.GestureDrag drag;
    
    private List<ReorderableWidget> childs;
    private ReorderableWidget? pressed_child;
    private ReorderableWidget? reorder_child;
    internal Adw.TimedAnimation? reorder_animation;
    private int reorder_index;
    internal int reorder_window_pos;
    private int reorder_pos;
    private int drag_offset;
    private bool continue_reorder;
    private bool dragging;
    
    construct {
        childs = new List<ReorderableWidget>();
        
        drag = new Gtk.GestureDrag();
        drag.drag_begin.connect(drag_started);
        drag.drag_update.connect(drag_update);
        drag.drag_end.connect(drag_end);
        
        add_controller(drag);
    }
    
    internal void get_reorder_position(out int pos) {
        pos = reorder_pos;
    }
    
    private void update_reordering() {
        int old_index = -1, new_index = -1;
        int pos;
        
        if (!dragging) return;
        
        get_reorder_position(out pos);
        
        reorder_window_pos = pos;
        
        queue_allocate();
        
        for (int i = 0; i < childs.length(); i++) {
            var child = childs.nth_data(i);
            var center = child.unshifted_pos + 100 / 2;
            
            if (child == reorder_child) old_index = i;
            
            if (pos + 100 > center && center >= pos && new_index < 0)
                new_index = i;
            
            if (old_index >= 0 && new_index >= 0) break; 
        }
        
        if (new_index < 0) new_index = (int) childs.length() - 1;
        
        for (int i = 0; i < childs.length(); i++) {
            var child = childs.nth_data(i);
            
            double offset = 0;
            if (i > old_index && i <= new_index) offset = -1;
            if (i < old_index && i >= new_index) offset = 1;
            
            child.animate_reorder_offset(offset);
        }
        
        reorder_index = new_index;
    }
    
    private void force_end_reordering() {
        if (dragging || reorder_child == null) return;
        
        if (reorder_animation != null)
            reorder_animation.skip();
        
        foreach (var child in childs)
            if (child.reorder_animation != null)
                child.reorder_animation.skip();
    }
    
    private void reset_reorder_animations() {
        if (!Adw.get_enable_animations(this)) return;
        
        var original_index = childs.index(reorder_child);
        
        if (reorder_index > original_index)
            for (int i = original_index + 1; i <= reorder_index; i++)
                childs.nth_data(i).animate_reorder_offset(0);
        
        if (reorder_index < original_index)
            for (int i = reorder_index; i < original_index; i++)
                childs.nth_data(i).animate_reorder_offset(0);
    }
    
    private void start_reordering(ReorderableWidget child, double x, double y) {
        if (dragging) return;
        
        continue_reorder = child == reorder_child;
        
        if (continue_reorder) {
            if (reorder_animation != null)
                reorder_animation.skip();
            
            reset_reorder_animations();
            
            reorder_pos = (int) (x - drag_offset);
        } else
            force_end_reordering();
        
        dragging = true;
        
        if (!continue_reorder) {
            reorder_child = child;
        }
    }
    
    private int get_child_pos(ReorderableWidget child, bool final) {
        if (child == reorder_child) return reorder_window_pos;
        
        return final ? child.final_pos : child.pos;
    }
    
    private void drag_started(double start_x, double start_y) {
        var widget = pick(start_x, start_y, Gtk.PickFlags.DEFAULT);
        if (widget != this) {
            for (var parent = widget.parent; !(parent is ReorderableList); parent = parent.parent) {
                if (parent is ReorderableWidget) {
                    pressed_child = (ReorderableWidget) parent;
                    break;
                }
            }
        }
        
        if (pressed_child == null) return;
        
        drag_offset = (int) start_y - get_child_pos(pressed_child, false);
        
        if (reorder_animation == null) {
            reorder_pos = (int) start_y - drag_offset;
        }
    }
    
    private void drag_update(double offset_x, double offset_y) {
        double start_x, start_y, x, y;
        if (pressed_child == null) {
            drag.set_state(Gtk.EventSequenceState.DENIED);
            return;
        }
        
        drag.get_start_point(out start_x, out start_y);
        
        x = start_x + offset_x;
        y = start_y + offset_y;
        
        start_reordering(pressed_child, x, y);
        
        if (!dragging) {
            drag.set_state(Gtk.EventSequenceState.DENIED);
            return;
        }
        
        reorder_pos = (int) y - drag_offset;
        
        update_reordering();
    }
    
    private void drag_end() {
        if (!dragging) return;
        
        dragging = false;
        
        var dest_child = childs.nth_data(reorder_index);
        
        animate_reordering(dest_child);
        
        continue_reorder = false;
    }
    
    internal void check_end_reordering() {
        if (dragging || reorder_child == null || continue_reorder) return;
        
        if (reorder_animation != null) return;
        
        foreach (var child in childs)
            if (child.reorder_animation != null)
                return;
        
        foreach (var child in childs) {
            child.end_reorder_offset = 0;
            child.reorder_offset = 0;
        }
        
        childs.remove(reorder_child);
        childs.insert(reorder_child, reorder_index);
        
        queue_allocate();
        reorder_child = null;
    }
    
    private void animate_reordering(ReorderableWidget dest_child) {
        reorder_animation = dest_child.animate_reordering();
        
        reorder_animation.play();
        
        check_end_reordering();
    }
    
    public void add_child(Gtk.Builder builder, Object child, string? type) {
        var widget = child as ReorderableWidget;
        if (widget == null) return;
        
        childs.append(widget);
        widget.set_parent(this);
        
        calculate_child_layout();
    }
    
    internal void get_position_for_index(double index, out int pos) {
        pos = (int) (100 * index);
    }
    
    private void calculate_child_layout() {
        double index = 0, final_index = 0;
        
        foreach (var child in childs) {
            if (!child.should_layout()) continue;
            
            get_position_for_index(final_index, out child.unshifted_pos);
            get_position_for_index(index + child.reorder_offset, out child.pos);
            get_position_for_index(final_index + child.end_reorder_offset, out child.final_pos);
            
            child.index = index;
            child.final_index = final_index;
            
            index += child.appear_progress;
            final_index++;
        }
    }
    
    public override void size_allocate(int width, int height, int baseline) {
        calculate_child_layout();
        
        foreach (var child in childs) {
            if (!child.should_layout()) continue;
            
            var child_allocation = Gtk.Allocation();
            child_allocation.x = 0;
            child_allocation.y = (child == reorder_child) ? reorder_window_pos : child.pos;
            child_allocation.width = width;
            child_allocation.height = 100;
            
            child.allocate_size(child_allocation, baseline);
        }
    }
    
    private void measure_test_list(Gtk.Orientation orientation, out int minimum, out int natural, bool animate) {
        if (get_first_child() == null) {
            minimum = 0;
            natural = 0;
            
            return;
        }
        
        if (orientation == Gtk.Orientation.VERTICAL) {
            int height = 0;
            
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                height += 100;
            }
            
            minimum = height;
            natural = minimum;
        } else {
            minimum = natural = 300;
        }
    }
    
    public override void measure(Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        measure_test_list(orientation, out minimum, out natural, true);
        
        minimum_baseline = -1;
        natural_baseline = -1;
    }
}

public class ReorderableWidget : Gtk.Widget {
    public Adw.TimedAnimation reorder_animation;
    public double appear_progress = 1;
    public double end_reorder_offset;
    public double reorder_offset;
    public double final_index;
    public double index;
    public int unshifted_pos;
    public int final_pos;
    public int pos;
    
    public string title { get; set; }
    
    private new ReorderableList parent {
        get {
            return get_parent() as ReorderableList;
        }
    }
    
    static construct {
        set_layout_manager_type(typeof(Gtk.BinLayout));
    }
    
    construct {
        add_css_class("card");
        
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 12
        };
        box.append(new Gtk.Image() {
            icon_name = "dialog-information-symbolic",
            pixel_size = 32
        });
        
        var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) {
            valign = Gtk.Align.CENTER
        };
        box.append(vbox);
        var label = new Gtk.Label("Test") { css_classes = { "title-4" }, halign = Gtk.Align.START };
        bind_property("title", label, "label", BindingFlags.SYNC_CREATE);
        vbox.append(label);
        vbox.append(new Gtk.Label("Lorem ipsum") { css_classes = { "body" } });
        
        box.set_parent(this);
    }
    
    public void animate_reorder_offset(double offset) {
        if (approx_value(end_reorder_offset, offset, double.EPSILON)) return;
        
        end_reorder_offset = offset;
        var start_offset = reorder_offset;
        
        if (reorder_animation != null)
            reorder_animation.skip();
        
        reorder_animation = new Adw.TimedAnimation(this, start_offset, offset, 250, new Adw.CallbackAnimationTarget(t => {
            reorder_offset = t;
            parent.queue_allocate();
        }));
        
        reorder_animation.done.connect(() => {
            reorder_animation = null;
            parent.check_end_reordering();
        });
        
        reorder_animation.play();
    }
    
    public Adw.TimedAnimation animate_reordering() {
        var anim = new Adw.TimedAnimation(this, 0, 1, 250, new Adw.CallbackAnimationTarget(t => {
            int pos1, pos2;
            
            parent.get_reorder_position(out pos1);
            parent.get_position_for_index(index, out pos2);
            
            parent.reorder_window_pos = (int) Adw.lerp(pos1, pos2, t);
            parent.queue_allocate();
        }));
        
        anim.done.connect(() => {
            parent.reorder_animation = null;
            parent.check_end_reordering();
        });
        
        return anim;
    }
}