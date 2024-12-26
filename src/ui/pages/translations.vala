[GtkTemplate (ui = "/me/paladin/Example/translations-page.ui")]
public class TranslationsPage : Adw.NavigationPage {
    public string lang { get; set; default = "en"; }
    public HashTable<string, string> russian = new HashTable<string, string>(str_hash, str_equal);
    public HashTable<string, string> english = new HashTable<string, string>(str_hash, str_equal);
    public HashTable<string, string> translations {
        get {
            if (lang == "ru") return russian;
            else return english;
        }
    }
    [GtkChild]
    private unowned Gtk.ToggleButton en;
    [GtkChild]
    private unowned Gtk.Label label;
    
    construct {
        russian["test"] = "Привет";
        english["test"] = "Hello";
        en.toggled.connect(() => {
            if (en.active) {
                lang = "en";
            } else {
                lang = "ru";
            }
        });
        set_label(label, "test");
    }
    
    private void set_label(Gtk.Label label, string translation) {
        bind_property("lang", label, "label", BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                targetval.set_string(translations[translation]);
                return true;
            }
        );
    }
}