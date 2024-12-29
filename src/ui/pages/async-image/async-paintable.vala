public class AsyncPaintable : Object {
    private unowned Gtk.Picture? target;
    
    private SuccessFunc success = () => {};
    private ErrorFunc error = (err) => warning(err.message);
    
    private AsyncPaintable() {}
    
    public static AsyncPaintable from_uri(string uri) {
        var loader = new AsyncPaintable();
        
        new Thread<void>("texture-thread", () => {
            try {
                var texture = Gdk.Texture.from_file(File.new_for_uri(uri));
                if (loader.target != null)
                    loader.target.paintable = texture;
                
                loader.success(texture);
            } catch (Error err) {
                loader.error(err);
            }
        });
        
        return loader;
    }
    
    public AsyncPaintable to_picture(Gtk.Picture picture) {
        target = picture;
        
        return this;
    }
    
    public AsyncPaintable on_error(ErrorFunc func) {
        error = func;
        
        return this;
    }
    
    public AsyncPaintable on_success(SuccessFunc func) {
        success = func;
        
        return this;
    }
    
    public delegate void SuccessFunc(Gdk.Paintable paintable);
    public delegate void ErrorFunc(Error err);
}