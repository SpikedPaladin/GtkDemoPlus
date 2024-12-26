public unowned Adw.NavigationView nav;

[GtkTemplate (ui = "/me/paladin/Example/main-window.ui")]
public class MainWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.NavigationView nav_view;
    [GtkChild]
    private unowned Gtk.ListView listview;
    [GtkChild]
    private unowned Adw.NavigationPage content_page;
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;
    [GtkChild]
    private unowned Notebook notebook;
    
    private string search_needle = "";
    private Gtk.SingleSelection selection;
    private Gtk.Filter filter;
    
    public MainWindow(Gtk.Application app) {
        Object(application: app);
        
        nav = nav_view;
        
        var action = new SimpleAction("run", null);
        action.activate.connect(on_run);
        add_action(action);
        
        var listmodel = create_demo_model();
        var treemodel = new Gtk.TreeListModel(listmodel, false, true, get_child_func);
        
        filter = new Gtk.CustomFilter(filter_by_name);
        var filter_model = new Gtk.FilterListModel(treemodel, filter);
        
        selection = new Gtk.SingleSelection(filter_model);
        selection.notify["selected-item"].connect(on_select);
        
        listview.model = selection;
        
        on_select();
    }
    
    [GtkCallback]
    public void search_changed() {
        var text = search_entry.get_text();
        
        search_needle = text;
        
        filter.changed(Gtk.FilterChange.DIFFERENT);
    }
    
    public bool filter_by_name(Object item) {
        var row = item as Gtk.TreeListRow;
        
        for (var parent = row; parent != null; parent = parent.get_parent()) {
            var demo = parent.get_item() as Demo;
            
            if (demo.title.down().contains(search_needle.down()))
                return true;
        }
        
        // Show row if any child matches
        var children = row.get_children();
        if (children != null) {
            var n = children.get_n_items();
            for (int i = 0; i < n; i++) {
                var demo = children.get_item(i) as Demo;
                
                if (demo.title.down().contains(search_needle.down()))
                    return true;
            }
        }
        
        return false;
    }
    
    public ListModel get_child_func(Object item) {
        var demo = item as Demo;
        return demo.children_model;
    }
    
    public void on_run() {
        get_selected_item().run();
    }
    
    public Demo get_selected_item() {
        var row = selection.get_selected_item() as Gtk.TreeListRow;
        return row.get_item() as Demo;
    }
    
    public void on_select() {
        var action = lookup_action("run") as SimpleAction;
        
        if (selection.get_selected_item() == null) {
            content_page.title = "No match";
            action.set_enabled(false);
            return;
        }
        
        var demo = get_selected_item();
        action.set_enabled(demo.func != null);
        content_page.title = demo.title;
        
        notebook.open(demo);
    }
    
    public ListStore create_demo_model() {
        var store = new ListStore(typeof(Demo));
        
        store.append(new Demo() {
            name = "main",
            title = "GTK Demo+"
        });
        
        var data = new Demo() {
            name = "sub",
            title = "Other",
        };
        var sub_store = new ListStore(typeof(Demo));
        data.children_model = sub_store;
        var demo = new Demo() {
            name = "transition",
            title = "Transition"
        };
        demo.func = () => new AnimationPage().present();
        sub_store.append(demo);
        store.append(data);
        
        demo = new Demo() {
            name = "reorder",
            title = "Reorderable List"
        };
        demo.func = () => new ReorderablePage().present();
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "transition",
            title = "Transition"
        };
        demo.func = () => new TransitionPage().present();
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "blur",
            title = "Blur Overlay"
        };
        demo.func = () => new BlurWindow().present();
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "stoy",
            title = "ShaderToy"
        };
        demo.func = () => new ShaderToyWindow().present();
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "translations",
            title = "Translations"
        };
        demo.func = () => nav.push_by_tag("translations");
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "intmap",
            title = "Interactive Map"
        };
        demo.func = () => new InteractiveMapWindow().present();
        
        sub_store.append(demo);
        
        demo = new Demo() {
            name = "async",
            title = "Async Image"
        };
        demo.func = () => nav.push_by_tag("async_image");
        
        sub_store.append(demo);
        
        return store;
    }
    
    /**
     * Required to ensure pages types
     * are registered in GObject system
     */
    public static void ensure_pages() {
        typeof(TransitionPage).ensure();
        typeof(TranslationsPage).ensure();
        typeof(AsyncImagePage).ensure();
    }
}
