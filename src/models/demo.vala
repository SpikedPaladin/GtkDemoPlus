public class Demo : Object {
    public string name { get; set; }
    public string title { get; set; }
    public ListModel? children_model { get; set; }
    public DemoRunFunc? func { get; set; }
    
    public void run() {
        if (func != null) func();
    }
}

public delegate void DemoRunFunc();