[GtkTemplate (ui = "/me/paladin/Example/notebook.ui")]
public class Notebook : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Box box;
    [GtkChild]
    private unowned Gtk.Stack stack;
    
    public void open(Demo demo) {
        if (demo.tag == "main") {
            
        }
    }
}