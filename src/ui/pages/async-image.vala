public class AsyncImage : Gtk.Widget {
    private string? _uri = null;
    public string? uri { get { return _uri; }
        set {
            _uri = value;
            load_uri.begin(value);
        }
    }
    private Gtk.Picture picture;
    
    construct {
        layout_manager = new Gtk.BinLayout();
        
        picture = new Gtk.Picture();
        picture.set_parent(this);
        
        picture.destroy.connect(() => {
            message("Pic destroy");
        });
    }
    
    public AsyncImage() {}
    
    public async void load_uri(string uri) {
        Gdk.Texture? texture = null;
        
        new Thread<void>("texture-thread", () => {
            try {
                var file = File.new_for_uri(uri);
                texture = Gdk.Texture.from_file(file);
            } catch (Error err) {
                warning("Error while loading texture: %s", err.message);
            } finally {
                Idle.add(load_uri.callback);
            }
        });
        
        yield;
        picture.set_paintable(texture);
    }
    
    public void set_paintable(Gdk.Paintable? paintable) {
        picture.set_paintable(paintable);
    }
    
    public override void dispose() {
        picture.unparent();
        base.dispose();
    }
}

public class AsyncImagePage : Adw.NavigationPage {
    private AsyncImage pic;
    
    construct {
        tag = "async_image";
        title = "Async Image";
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        var button = new Gtk.Button.with_label("Big");
        var button2 = new Gtk.Button.with_label("Vala");
        box.append(button);
        box.append(button2);
        box.append(new Adw.Spinner());
        
        pic = new AsyncImage();
        box.append(pic);
        
        button.clicked.connect(() => {
            pic.uri = "http://localhost:8888/test.png";
        });
        
        button2.clicked.connect(() => {
            pic.uri = "https://i.ibb.co/jDsgKx5/Vala.png";
        });
        
        child = box;
    }
    
    public override void unmap() {
        pic.set_paintable(null);
        base.unmap();
    }
}