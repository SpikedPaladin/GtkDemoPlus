public class AsyncImage : Gtk.Widget {
    private Gtk.Picture picture;
    private string? _uri = null;
    public string? uri { get { return _uri; }
        set {
            _uri = value;
            load_uri.begin(value);
        }
    }
    public string alternative_text {
        get { return picture.alternative_text; }
        set { picture.alternative_text = value; }
    }
    public bool can_shrink {
        get { return picture.can_shrink; }
        set { picture.can_shrink = value; }
    }
    public Gtk.ContentFit content_fit {
        get { return picture.content_fit; }
        set { picture.content_fit = value; }
    }
    
    construct {
        layout_manager = new Gtk.BinLayout();
        
        picture = new Gtk.Picture();
        picture.set_parent(this);
    }
    
    public AsyncImage() {}
    
    public async void load_uri(string uri) {
        Gdk.Texture? texture = null;
        
        new Thread<void>("texture-thread", () => {
            try {
                texture = Gdk.Texture.from_file(File.new_for_uri(uri));
            } catch (Error err) {
                warning("Error while loading texture: %s", err.message);
            } finally {
                Idle.add(load_uri.callback);
            }
        });
        
        yield;
        set_paintable(texture);
    }
    
    public void set_paintable(Gdk.Paintable? paintable) {
        picture.set_paintable(paintable);
    }
    
    public override void dispose() {
        picture.unparent();
        base.dispose();
    }
}