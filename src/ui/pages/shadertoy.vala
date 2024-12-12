public class ShaderToyWindow : Adw.Window {
    construct {
        var overlay = new Gtk.Overlay();
        overlay.child = new ShaderToy();
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        box.append(new Gtk.Button.with_label("Click") {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        });
        overlay.add_overlay(box);
        
        content = overlay;
    }
}

public class ShaderToy : Gtk.GLArea {
    private string image_shader;
    private bool image_shader_dirty;
    private bool error_set;
    private uint vao;
    private uint buffer;
    private GL.Program program = GL.NULL_PROGRAM;
    
    private float resolution[3];
    private float time;
    private float timedelta;
    private float mouse[4];
    private int frame;
    
    private int64 first_frame_time;
    private int64 first_frame;
    private uint tick;
    
    private const string default_image_shader = """
// Originally from: https://www.shadertoy.com/view/WlByzy
// License CC0: Neonwave style road, sun and city
//  The result of a bit of experimenting with neonwave style colors.

#define PI          3.141592654
#define TAU         (2.0*PI)

#define TIME        iTime
#define RESOLUTION  iResolution

vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash(in float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

float hash(in vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

float psin(float a) {
  return 0.5 + 0.5*sin(a);
}

float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float planex(vec2 p, float w) {
  return abs(p.y) - w;
}

float planey(vec2 p, float w) {
  return abs(p.x) - w;
}

float pmin(float a, float b, float k) {
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float sun(vec2 p) {
  const float ch = 0.0125;
  vec2 sp = p;
  vec2 cp = p;
  mod1(cp.y, ch*6.0);

  float d0 = circle(sp, 0.5);
  float d1 = planex(cp, ch);
  float d2 = p.y+ch*3.0;

  float d = d0;
  d = pmax(d, -max(d1, d2), ch*2.0);

  return d;
}

float city(vec2 p) {
  float sd = circle(p, 0.5);
  float cd = 1E6;

  const float count = 5.0;
  const float width = 0.1;

  for (float i = 0.0; i < count; ++i) {
    vec2 pp = p;
    pp.x += i*width/count;
    float nn = mod1(pp.x, width);
    float rr = hash(nn+sqrt(3.0)*i);
    float dd = box(pp-vec2(0.0, -0.5), vec2(0.02, 0.35*(1.0-smoothstep(0.0, 5.0, abs(nn)))*rr+0.1));
    cd = min(cd, dd);
  }

  return max(sd,cd);
}
vec3 sunEffect(vec2 p) {
  float aa = 4.0 / RESOLUTION.y;

  vec3 col = vec3(0.1);
  vec3 skyCol1 = hsv2rgb(vec3(283.0/360.0, 0.83, 0.16));
  vec3 skyCol2 = hsv2rgb(vec3(297.0/360.0, 0.79, 0.43));
  col = mix(skyCol1, skyCol2, pow(clamp(0.5*(1.0+p.y+0.1*sin(4.0*p.x+TIME*0.5)), 0.0, 1.0), 4.0));

  p.y -= 0.375;
  float ds = sun(p);
  float dc = city(p);

  float dd = circle(p, 0.5);

  vec3 sunCol = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 1.0), clamp(0.5 - 1.0*p.y, 0.0, 1.0));
  vec3 glareCol = sqrt(sunCol);
  vec3 cityCol = sunCol*sunCol;

  col += glareCol*(exp(-30.0*ds))*step(0.0, ds);


  float t1 = smoothstep(0.0, 0.075, -dd);
  float t2 = smoothstep(0.0, 0.3, -dd);
  col = mix(col, sunCol, smoothstep(-aa, 0.0, -ds));
  col = mix(col, glareCol, smoothstep(-aa, 0.0, -dc)*t1);
  col += vec3(0.0, 0.25, 0.0)*(exp(-90.0*dc))*step(0.0, dc)*t2;

//  col += 0.3*psin(d*400);

  return col;
}

float ground(vec2 p) {
  p.y += TIME*80.0;
  p *= 0.075;
  vec2 gp = p;
  gp = fract(gp) - vec2(0.5);
  float d0 = abs(gp.x);
  float d1 = abs(gp.y);
  float d2 = circle(gp, 0.05);

  const float rw = 2.5;
  const float sw = 0.0125;

  vec2 rp = p;
  mod1(rp.y, 12.0);
  float d3 = abs(rp.x) - rw;
  float d4 = abs(d3) - sw*2.0;
  float d5 = box(rp, vec2(sw*2.0, 2.0));
  vec2 sp = p;
  mod1(sp.y, 4.0);
  sp.x = abs(sp.x);
  sp -= vec2(rw - 0.125, 0.0);
  float d6 = box(sp, vec2(sw, 1.0));

  float d = d0;
  d = pmin(d, d1, 0.1);
  d = max(d, -d3);
  d = min(d, d4);
  d = min(d, d5);
  d = min(d, d6);

  return d;
}

vec3 groundEffect(vec2 p) {
  vec3 ro = vec3(0.0, 20.0, 0.0);
  vec3 ww = normalize(vec3(0.0, -0.025, 1.0));
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize(p.x*uu + p.y*vv + 2.5*ww);

  float distg = (-9.0 - ro.y)/rd.y;

  const vec3 shineCol = 0.75*vec3(0.5, 0.75, 1.0);
  const vec3 gridCol = vec3(1.0);

  vec3 col = vec3(0.0);
  if (distg > 0.0) {
    vec3 pg = ro + rd*distg;
    float aa = length(dFdx(pg))*0.0002*RESOLUTION.x;

    float dg = ground(pg.xz);

    col = mix(col, gridCol, smoothstep(-aa, 0.0, -(dg+0.0175)));
    col += shineCol*(exp(-10.0*clamp(dg, 0.0, 1.0)));
    col = clamp(col, 0.0, 1.0);

//    col += 0.3*psin(dg*100);
    col *= pow(1.0-smoothstep(ro.y*3.0, 220.0+ro.y*2.0, distg), 2.0);
  }

  return col;
}

vec3 postProcess(vec3 col, vec2 q)  {
  col = clamp(col,0.0,1.0);
//  col=pow(col,vec3(0.75));
  col=col*0.6+0.4*col*col*(3.0-2.0*col);
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

vec3 effect(vec2 p, vec2 q) {
  vec3 col = vec3(0.0);

  vec2 off = vec2(0.0, 0.0);

  col += sunEffect(p+off);
  col += groundEffect(p+off);

  col = postProcess(col, q);
  return col;
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
  vec2 q = fragCoord/iResolution.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x / RESOLUTION.y;

  vec3 col = effect(p, q);

  fragColor = vec4(col, 1.0);
}
""";
    
    private const string shadertoy_vertex_shader = """
#version 150 core

uniform vec3 iResolution;

in vec2 position;
out vec2 fragCoord;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);

    // Convert from OpenGL coordinate system (with origin in center
    // of screen) to Shadertoy/texture coordinate system (with origin
    // in lower left corner)
    fragCoord = (gl_Position.xy + vec2(1.0)) / vec2(2.0) * iResolution.xy;
}""";

    private const string fragment_prefix = """
#version 150 core

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec4      iDate;                 // (year, month, day, time in seconds)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

in vec2 fragCoord;
out vec4 vFragColor;""";

    private const string fragment_suffix = """
void main() {
    vec4 c;
    mainImage(c, fragCoord);
    vFragColor = c;
}""";
    
    construct {
        set_allowed_apis(Gdk.GLAPI.GL);
        image_shader = default_image_shader;
        
        tick = add_tick_callback(tick_callback);
        
        var drag = new Gtk.GestureDrag();
        add_controller(drag);
        
        drag.drag_begin.connect((x, y) => {
            int height = get_height();
            int scale = get_scale_factor();
            
            mouse[0] = (float) x * scale;
            mouse[1] = (float) ((height - y) * scale);
            mouse[2] = mouse[0];
            mouse[3] = mouse[1];
        });
        
        drag.drag_update.connect((dx, dy) => {
            double x, y;
            
            drag.get_start_point(out x, out y);
            
            if (x >= 0 && x < get_width() && x >= 0 && y < get_height()) {
                mouse[0] = (float) x * scale_factor;
                mouse[1] = (float) (get_height() - y) * scale_factor;
            }
        });
        
        drag.drag_end.connect(() => {
            mouse[2] = -mouse[2];
            mouse[3] = -mouse[3];
        });
    }
    
    private void init_shaders() throws Gdk.GLError {
        var vertex_shader = shadertoy_vertex_shader;
        var fragment_shader = fragment_prefix + image_shader + fragment_suffix;
        
        var vertex = create_shader(GL.VERTEX_SHADER, vertex_shader);
        if (vertex == 0)
            throw new Gdk.GLError.COMPILATION_FAILED("Failed to create vertex shader");
        
        var fragment = create_shader(GL.FRAGMENT_SHADER, fragment_shader);
        if (fragment == 0) {
            GL.delete_shader(vertex);
            throw new Gdk.GLError.COMPILATION_FAILED("Failed to create fragment shader");
        }
        
        var program = GL.Program();
        program.attach_shader(vertex);
        program.attach_shader(fragment);
        
        try {
            program.link();
        } catch (Gdk.GLError err) {
            GL.delete_shader(vertex);
            GL.delete_shader(fragment);
            throw err;
        }
        
        if (this.program != 0)
            GL.delete_program(this.program);
        
        this.program = program;
    }
    
    private GL.Shader create_shader(GL.GLenum shader_type, string source) {
        var shader = GL.Shader(shader_type);
        shader.load(source);
        shader.compile();
        
        return shader;
    }
    
    public override bool render(Gdk.GLContext context) {
        if (get_error() != null)
            return false;
        
        if (image_shader_dirty)
            realize_shader();
        
        GL.clear_color(0, 0, 0, 0);
        GL.clear(GL.COLOR_BUFFER_BIT);
        
        GL.use_program(program);
        
        program.set_float("iTime", time);
        program.set_float("iTimeDelta", timedelta);
        program.set_int("iFrame", frame);
        program.get_uniform_location("iMouse").set_4fv(ref mouse);
        program.get_uniform_location("iResolution").set_3fv(ref resolution);
        
        GL.bind_buffer(GL.ARRAY_BUFFER, buffer);
        GL.enable_attrib_array(0);
        GL.attrib_array_pointer(0, 4, GL.FLOAT);
        
        GL.draw_arrays(GL.TRIANGLES, 0, 6);
        
        GL.disable_attrib_array(0);
        GL.bind_buffer(GL.ARRAY_BUFFER, 0);
        GL.use_program(0);
        
        GL.flush();
        
        return true;
    }
    
    public override void resize(int width, int height) {
        base.resize(width, height);
        
        resolution[0] = width;
        resolution[1] = height;
        resolution[2] = 1;
        
        GL.viewport(0, 0, width, height);
    }
    
    public override void realize() {
        base.realize();
        
        make_current();
        
        if (get_error() != null)
            return;
        
        vao = GL.gen_vertex_array();
        GL.bind_vertex_array(vao);
        
        buffer = GL.gen_buffer();
        GL.bind_buffer(GL.ARRAY_BUFFER, buffer);
        GL.buffer_floats(
            GL.ARRAY_BUFFER,
            {
                -1.0f, -1.0f, 0.0f, 1.0f,
                -1.0f,  1.0f, 0.0f, 1.0f,
                1.0f,  1.0f, 0.0f, 1.0f,

                -1.0f, -1.0f, 0.0f, 1.0f,
                1.0f,  1.0f, 0.0f, 1.0f,
                1.0f, -1.0f, 0.0f, 1.0f,
            },
            GL.STATIC_DRAW
        );
        GL.bind_buffer(GL.ARRAY_BUFFER, 0);
        
        realize_shader();
    }
    
    public void realize_shader() {
        try {
            init_shaders();
        } catch (Gdk.GLError err) {
            error_set = true;
            set_error(err);
        }
        
        first_frame_time = 0;
        first_frame = 0;
        
        image_shader_dirty = false;
    }
    
    public override void unrealize() {
        base.unrealize();
    }
    
    private bool tick_callback(Gtk.Widget _, Gdk.FrameClock clock) {
        var frame = clock.get_frame_counter();
        var frame_time = clock.get_frame_time();
        
        float previous_time = 0;
        
        if (first_frame_time == 0) {
            first_frame_time = frame_time;
            first_frame = frame;
        } else previous_time = time;
        
        time = (frame_time - first_frame_time) / 1000000F;
        this.frame = (int) (frame - first_frame);
        timedelta = time - previous_time;
        
        queue_draw();
        
        return Source.CONTINUE;
    }
    
    ~ShaderToy() {
        
    }
}