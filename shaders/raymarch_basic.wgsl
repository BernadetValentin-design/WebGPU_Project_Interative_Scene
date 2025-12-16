// Basic Ray Marching with Dynamic Primitives

struct Shape {
    transform: vec4<f32>, // xyz = pos, w = type (0:Sphere, 1:Box, 2:Torus)
    params: vec4<f32>,    // xyz = size/radius, w = active/blend
    color: vec4<f32>,     // xyz = color, w = padding
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var<storage, read> shapes: array<Shape>;

// Scene description - returns distance
fn get_dist_shape(p: vec3<f32>, type_id: i32, params: vec3<f32>) -> f32 {
    if (type_id == 0) { // Sphere
        return sd_sphere(p, params.x);
    } else if (type_id == 1) { // Box
        return sd_box(p, params);
    } else if (type_id == 2) { // Torus
        return sd_torus(p, params.xy);
    }
    return MAX_DIST;
}

fn get_dist(p: vec3<f32>) -> f32 {
  var d = MAX_DIST;
  let k = 0.5; // Smoothness factor

  let count = arrayLength(&shapes);
  for (var i = 0u; i < count; i++) {
    let shape = shapes[i];
    if (shape.params.w < 0.5) { continue; }

    let pos = p - shape.transform.xyz;
    let dist = get_dist_shape(pos, i32(shape.transform.w), shape.params.xyz);
    
    // Smooth Union
    let h = clamp(0.5 + 0.5 * (d - dist) / k, 0.0, 1.0);
    d = mix(d, dist, h) - k * h * (1.0 - h);
  }

  // Ground plane (Hard union)
  let plane_dist = p.y + 1.0;
  return min(d, plane_dist);
}

fn get_scene_color(p: vec3<f32>) -> vec3<f32> {
  var d = MAX_DIST;
  var color = vec3<f32>(0.0);
  let k = 0.5; // Smoothness factor

  let count = arrayLength(&shapes);
  for (var i = 0u; i < count; i++) {
    let shape = shapes[i];
    if (shape.params.w < 0.5) { continue; }

    let pos = p - shape.transform.xyz;
    let dist = get_dist_shape(pos, i32(shape.transform.w), shape.params.xyz);
    let col = shape.color.rgb;

    // Smooth Union
    let h = clamp(0.5 + 0.5 * (d - dist) / k, 0.0, 1.0);
    d = mix(d, dist, h) - k * h * (1.0 - h);
    color = mix(color, col, h);
  }

  // Ground plane color logic
  let plane_dist = p.y + 1.0;
  if (plane_dist < d) {
     let checker = floor(p.x) + floor(p.z);
     let col1 = vec3<f32>(0.9, 0.9, 0.9);
     let col2 = vec3<f32>(0.2, 0.2, 0.2);
     return select(col2, col1, i32(checker) % 2 == 0);
  }

  return color;
}

// Ray marching function - returns distance
fn ray_march(ro: vec3<f32>, rd: vec3<f32>) -> f32 {
  var d = 0.0;

  for (var i = 0; i < MAX_STEPS; i++) {
    let p = ro + rd * d;
    let dist = get_dist(p);
    d += dist;

    if dist < SURF_DIST || d > MAX_DIST {
      break;
    }
  }

  return d;
}

// Calculate normal using gradient
fn get_normal(p: vec3<f32>) -> vec3<f32> {
  let e = vec2<f32>(0.001, 0.0);
  let n = vec3<f32>(
    get_dist(p + e.xyy) - get_dist(p - e.xyy),
    get_dist(p + e.yxy) - get_dist(p - e.yxy),
    get_dist(p + e.yyx) - get_dist(p - e.yyx)
  );
  return normalize(n);
}

@fragment
fn fs_main(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {
  let uv = (fragCoord.xy - uniforms.resolution * 0.5) / min(uniforms.resolution.x, uniforms.resolution.y);

  // Orbital Control
  // uniforms.mouse.x is Yaw, uniforms.mouse.y is Pitch
  let yaw = uniforms.mouse.x;
  let pitch = clamp(uniforms.mouse.y, 0.05, 1.5);

  // Camera Coords
  let cam_dist = uniforms.mouse.z; 
  let cam_target = uniforms.cam_target.xyz;
  let cam_pos = cam_target + vec3<f32>(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * cam_dist;

  // Camera Matrix
  let cam_forward = normalize(cam_target - cam_pos);
  let cam_right = normalize(cross(cam_forward, vec3<f32>(0.0, 1.0, 0.0)));
  let cam_up = cross(cam_right, cam_forward); 

  // Ray Direction
  let focal_length = 1.5;
  let rd = normalize(cam_right * uv.x - cam_up * uv.y + cam_forward * focal_length);

  // Ray march
  let d = ray_march(cam_pos, rd);

  if d < MAX_DIST {
    // Hit something
    let hit_pos = cam_pos + rd * d;
    let normal = get_normal(hit_pos);

    // Diffuse Lighting
    let light_pos = vec3<f32>(2.0, 5.0, -2.0);
    let light_dir = normalize(light_pos - hit_pos);
    let diffuse = max(dot(normal, light_dir), 0.0);

    // Shadow Casting
    let shadow_origin = hit_pos + normal * 0.01;
    let shadow_d = ray_march(shadow_origin, light_dir);
    let shadow = select(0.3, 1.0, shadow_d > length(light_pos - shadow_origin));

    // Smooth Color
    let ambient = 0.2;
    let albedo = get_scene_color(hit_pos);
    
    let phong = albedo * (ambient + diffuse * shadow * 0.8);

    // Exponential Fog
    let fog = exp(-d * 0.02);
    let color = mix(MAT_SKY_COLOR, phong, fog);

    return vec4<f32>(gamma_correct(color), 1.0);
  }

  // Sky gradient
  let sky = mix(MAT_SKY_COLOR, MAT_SKY_COLOR * 0.8, uv.y * 0.5 + 0.5);
  return vec4<f32>(gamma_correct(sky), 1.0);
}

// Gamma Correction
fn gamma_correct(color: vec3<f32>) -> vec3<f32> {
  return pow(color, vec3<f32>(1.0 / 2.2));
}

// Constants
const MAX_DIST: f32 = 100.0;
const SURF_DIST: f32 = 0.001;
const MAX_STEPS: i32 = 128;
const MAT_SKY_COLOR: vec3<f32> = vec3<f32>(0.1, 0.1, 0.15);

// SDF Primitives
fn sd_sphere(p: vec3<f32>, r: f32) -> f32 {
  return length(p) - r;
}

fn sd_box(p: vec3<f32>, b: vec3<f32>) -> f32 {
  let q = abs(p) - b;
  return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

fn sd_torus(p: vec3<f32>, t: vec2<f32>) -> f32 {
  let q = vec2<f32>(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}
