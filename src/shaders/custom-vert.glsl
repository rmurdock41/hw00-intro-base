#version 300 es

// Vertex attributes
in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;
in vec2 vs_UV;

// Matrices
uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;

// Time uniform for animation
uniform float u_Time;

// Output to fragment shader
out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec3 fs_WorldPos;

// Light position
const vec4 lightPos = vec4(5, 5, 3, 1);

// 3D Hash function
float hash3D(float x, float y, float z) {
    return fract(sin(x * 12.9898 + y * 78.233 + z * 45.164) * 43758.5453);
}

// 3D Gradient function - generates pseudo-random unit vectors
vec3 grad3D(float x, float y, float z) {
    float r1 = hash3D(x, y, z);
    float r2 = hash3D(x + 1.0, y + 1.0, z + 1.0);
    
    float theta = r1 * 2.0 * 3.14159265359;
    float phi = acos(2.0 * r2 - 1.0);
    
    float sinPhi = sin(phi);
    return vec3(
        sinPhi * cos(theta),
        sinPhi * sin(theta),
        cos(phi)
    );
}

// 3D Perlin noise function
float perlinNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    // Smooth interpolation curve
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    // Calculate dot products at cube corners
    float d000 = dot(grad3D(i.x,     i.y,     i.z),     f - vec3(0.0, 0.0, 0.0));
    float d100 = dot(grad3D(i.x + 1.0, i.y,     i.z),     f - vec3(1.0, 0.0, 0.0));
    float d010 = dot(grad3D(i.x,     i.y + 1.0, i.z),     f - vec3(0.0, 1.0, 0.0));
    float d110 = dot(grad3D(i.x + 1.0, i.y + 1.0, i.z),     f - vec3(1.0, 1.0, 0.0));
    float d001 = dot(grad3D(i.x,     i.y,     i.z + 1.0), f - vec3(0.0, 0.0, 1.0));
    float d101 = dot(grad3D(i.x + 1.0, i.y,     i.z + 1.0), f - vec3(1.0, 0.0, 1.0));
    float d011 = dot(grad3D(i.x,     i.y + 1.0, i.z + 1.0), f - vec3(0.0, 1.0, 1.0));
    float d111 = dot(grad3D(i.x + 1.0, i.y + 1.0, i.z + 1.0), f - vec3(1.0, 1.0, 1.0));
    
    // Trilinear interpolation
    float ix00 = mix(d000, d100, u.x);
    float ix10 = mix(d010, d110, u.x);
    float ix01 = mix(d001, d101, u.x);
    float ix11 = mix(d011, d111, u.x);
    
    float iy0 = mix(ix00, ix10, u.y);
    float iy1 = mix(ix01, ix11, u.y);
    
    return mix(iy0, iy1, u.z);
}

void main() {
    vec4 modelposition = vs_Pos;
    
    // Create animated 3D position for noise sampling
    vec3 noisePos = vs_Pos.xyz * 2.0 + vec3(u_Time * 0.5);
    
    // Generate noise displacement using multiple octaves
    float noise = perlinNoise3D(noisePos * 0.5);
    noise += perlinNoise3D(noisePos * 1.0) * 0.5;
    noise += perlinNoise3D(noisePos * 2.0) * 0.25;
    
    // Apply trigonometric displacement based on time and noise
    vec3 displacement = vs_Nor.xyz * sin(u_Time + noise * 3.14159) * 0.3;
    displacement += vs_Pos.xyz * cos(u_Time * 0.8 + noise * 2.0) * 0.1;
    
    modelposition.xyz += displacement;
    
    // Store world position for fragment shader
    fs_WorldPos = (u_Model * modelposition).xyz;
    
    // Transform position to clip space
    gl_Position = u_ViewProj * u_Model * modelposition;
    
    // Transform normal
    fs_Nor = normalize(u_ModelInvTr * vs_Nor);
    
    // Calculate light vector
    fs_LightVec = normalize(lightPos - (u_Model * modelposition));
    
    // Pass color
    fs_Col = vs_Col;
}