[GtkTemplate (ui = "/me/paladin/Example/animation-page.ui")]
public class AnimationPage : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.Fixed fixed;
    [GtkChild]
    private unowned Gtk.Frame frame;
    [GtkChild]
    private unowned Gtk.Adjustment x;
    [GtkChild]
    private unowned Gtk.Adjustment y;
    [GtkChild]
    private unowned Gtk.Adjustment pers;
    [GtkChild]
    private unowned Gtk.Adjustment rot_y;
    
    [GtkCallback]
    private void start_animation() {
        var target = new Adw.PropertyAnimationTarget (rot_y, "value");
        var params = new Adw.SpringParams (1, 4, 100.0);
        var animation = new Adw.SpringAnimation(this, 0, 360, params, target);
        animation.play();
    }
    
    [GtkCallback]
    private void on_apply() {
        var transform = new Gsk.Transform()
            .translate({(float) x.value, (float) y.value})
            .perspective((float) pers.value)
            .translate_3d({-100, -100, 200 / 6})
            .rotate_3d((float) rot_y.value, Graphene.Vec3.y_axis())
            .translate_3d({0, 0, 100})
            .translate_3d({-100, -100, 0});
        
        fixed.set_child_transform(frame, transform);
    }
}