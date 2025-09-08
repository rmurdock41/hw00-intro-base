#version 300 es

precision highp float;

// Input from vertex shader
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec3 fs_WorldPos;

// Uniforms
uniform float u_Time;
uniform vec4 u_Color;

// Output color
out vec4 out_Col;

// 3D Hash function
float hash3D(float x, float y, float z) {
    return fract(sin(x * 12.9898 + y * 78.233 + z * 45.164) * 43758.5453);
}

// 3D Gradient function
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

// Fractional Brownian Motion (FBM) using multiple octaves of Perlin noise
float fbm(vec3 p) {
    float result = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 6; i++) {
        result += perlinNoise3D(p * frequency) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return result;
}

// Remap function to convert noise from [-1,1] to [min,max]
float remap(float value, float minOutput, float maxOutput) {
    float t = (value + 1.0) * 0.5; // Normalize to [0,1]
    return mix(minOutput, maxOutput, t);
}

void main() {
    // Create animated 3D coordinates for noise sampling
    vec3 noiseCoord = fs_WorldPos * 0.8 + vec3(u_Time * 0.3, u_Time * 0.2, u_Time * 0.1);
    
    // Generate different noise patterns
    float mainNoise = fbm(noiseCoord * 0.5);
    float detailNoise = perlinNoise3D(noiseCoord * 2.0);
    float colorNoise = perlinNoise3D(noiseCoord * 1.5 + vec3(100.0));
    
    // Create dynamic color based on noise
    vec3 noiseColor = vec3(
        remap(mainNoise + detailNoise * 0.3, 0.2, 1.0),
        remap(colorNoise * 0.8 + sin(u_Time + mainNoise), 0.3, 0.9),
        remap(detailNoise + cos(u_Time * 0.7), 0.4, 1.0)
    );
    
    // Blend with the uniform color
    vec3 finalColor = mix(u_Color.rgb, noiseColor, 0.7);
    
    // Apply some variation based on noise
    float intensity = remap(mainNoise, 0.5, 1.2);
    finalColor *= intensity;
    
    // Add some pulsing effect
    finalColor += vec3(sin(u_Time + mainNoise * 3.14159) * 0.1);
    
    // Basic Lambert lighting
    float lambert = max(dot(fs_Nor.xyz, fs_LightVec.xyz), 0.0);
    finalColor *= (0.3 + 0.7 * lambert); // Ambient + diffuse
    
    // Output final color
    out_Col = vec4(finalColor, u_Color.a);
}