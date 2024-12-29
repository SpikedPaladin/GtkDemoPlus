[GtkTemplate (ui = "/me/paladin/Example/async-image-page.ui")]
public class AsyncImagePage : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.Picture pic;
    
    [GtkCallback]
    private void load_big() {
        AsyncPaintable
            .from_uri("https://fakeimg.pl/3840x2160")
            .to_picture(pic);
    }
    
    [GtkCallback]
    private void load_small() {
        AsyncPaintable
            .from_uri("https://fakeimg.pl/1920x1080")
            .to_picture(pic);
    }
    
    public override void unmap() {
        pic.paintable = null;
        base.unmap();
    }
}