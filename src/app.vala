public static Settings settings;

public class Example : Adw.Application {
    public MainWindow main_window;
    
    private static Example _instance;
    public static Example instance {
        get {
            if (_instance == null)
                _instance = new Example();
            
            return _instance;
        }
    }
    
    construct {
        application_id = "me.paladin.Example";
        flags = ApplicationFlags.DEFAULT_FLAGS;
        settings = new Settings("me.paladin.Example");
    }
    
    public override void activate() {
        if (main_window != null) {
            main_window.present();
            return;
        }
        
        MainWindow.ensure_pages();
        
        main_window = new MainWindow(this);
        main_window.present();
    }
    
    public static int main(string[] args) {
        var app = Example.instance;
        return app.run(args);
    }
}
