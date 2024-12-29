[GtkTemplate (ui = "/me/paladin/Example/animation-page.ui")]
public class AnimationPage : Adw.NavigationPage {
    private Adw.TimedAnimation anim;
    
    [GtkChild]
    private unowned Gtk.Fixed fixed;
    [GtkChild]
    private unowned Gtk.Image image;
    
    public float rotation {
        get;
        set;
    }
    
    construct {
        anim = new Adw.TimedAnimation(this, 0, 360, 2000,
            new Adw.PropertyAnimationTarget(this, "rotation")
        );
        
        anim.set_repeat_count(0);
        
        notify["rotation"].connect(() => on_apply());
        
        on_apply();
    }
    
    public override void map() {
        base.map();
        
        anim.play();
    }
    
    public override void unmap() {
        base.unmap();
        
        anim.pause();
    }
    
    private void on_apply() {
        var transform = new Gsk.Transform()
            .translate({ 300, 300 })
            .perspective(600)
            .rotate_3d(rotation, Graphene.Vec3.y_axis())
            .translate_3d({-150, -150, 0});
        
        fixed.set_child_transform(image, transform);
    }
}