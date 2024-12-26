public class Translations : Adw.Window {
    public string lang { get; set; default = "ru"; }
    public HashTable<string, string> russian = new HashTable<string, string>(str_hash, str_equal);
    public HashTable<string, string> english = new HashTable<string, string>(str_hash, str_equal);
    public HashTable<string, string> translations {
        get {
            if (lang == "ru") return russian;
            else return english;
        }
    }
    
    construct {
        russian["test"] = "Привет";
        
        english["test"] = "Hello";
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        var bbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        bbox.add_css_class("linked");
        
        var rus = new Gtk.ToggleButton.with_label("RU") {
            active = true
        };
        var eng = new Gtk.ToggleButton.with_label("EN");
        eng.toggled.connect(() => {
            if (eng.active) {
                lang = "en";
            } else {
                lang = "ru";
            }
        });
        eng.group = rus;
        bbox.append(rus);
        bbox.append(eng);
        
        var label = new Gtk.Label("");
        set_label(label, "test");
        
        box.append(bbox);
        box.append(label);
        content = box;
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