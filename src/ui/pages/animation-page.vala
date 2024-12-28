[GtkTemplate (ui = "/me/paladin/Example/animation-page.ui")]
public class AnimationPage : Adw.NavigationPage {
    private Adw.TimedAnimation anim;
    
    [GtkChild]
    private unowned Gtk.Fixed fixed;
    [GtkChild]
    private unowned Gtk.Image image;
    [GtkChild]
    private unowned Gtk.Adjustment x;
    [GtkChild]
    private unowned Gtk.Adjustment y;
    [GtkChild]
    private unowned Gtk.Adjustment pers;
    [GtkChild]
    private unowned Gtk.Adjustment rot_y;
    
    construct {
        anim = new Adw.TimedAnimation(this, 0, 360, 2000,
            new Adw.PropertyAnimationTarget (rot_y, "value")
        );
        
        on_apply();
    }
    
    [GtkCallback]
    private void start_animation() {
        if (anim.state != Adw.AnimationState.PLAYING)
            anim.play();
    }
    
    [GtkCallback]
    private void on_apply() {
        var transform = new Gsk.Transform()
            .translate({(float) x.value + 150, (float) y.value + 150 })
            .perspective((float) pers.value)
            .rotate_3d((float) rot_y.value, Graphene.Vec3.y_axis())
            .translate_3d({-150, -150, 0});
        
        fixed.set_child_transform(image, transform);
    }
}