[GtkTemplate (ui = "/me/paladin/Example/blur-page.ui")]
public class BlurPage : Adw.NavigationPage {
    [GtkChild]
    public unowned BlurOverlay blur_overlay;
}