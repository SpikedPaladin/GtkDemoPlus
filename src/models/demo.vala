public class Demo : Object {
    public string tag { get; set; }
    public string title { get; set; }
    public bool has_page { get; set; default = true; }
    public ListModel? children_model { get; set; }
    public DemoRunFunc? func { get; set; }
    
    public void run() {
        if (func != null) func();
        else nav.push_by_tag(tag);
    }
}

public delegate void DemoRunFunc();