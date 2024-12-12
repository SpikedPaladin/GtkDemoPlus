[GtkTemplate (ui = "/me/paladin/Example/add-item-dialog.ui")]
public class AddItemDialog : Adw.Dialog {
    [GtkChild]
    private unowned Gtk.Entry title_entry;
    [GtkChild]
    private unowned Gtk.Entry subtitle_entry;
    
    [GtkCallback]
    public void on_add_clicked() {
        add(title_entry.text, subtitle_entry.text);
    }
    
    public signal void add(string title, string subtitle);
}