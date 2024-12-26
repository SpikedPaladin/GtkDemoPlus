[GtkTemplate (ui = "/me/paladin/Example/async-image-page.ui")]
public class AsyncImagePage : Adw.NavigationPage {
    [GtkChild]
    private unowned AsyncImage img;
    
    [GtkCallback]
    private void load_big() {
        img.uri = "https://fakeimg.pl/3840x2160";
    }
    
    [GtkCallback]
    private void load_vala() {
        img.uri = "https://fakeimg.pl/1920x1080";
    }
    
    public override void unmap() {
        img.set_paintable(null);
        base.unmap();
    }
}