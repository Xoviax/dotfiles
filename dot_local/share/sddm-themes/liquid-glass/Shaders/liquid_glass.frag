#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 uResolution;         // Card resolution in pixels (width, height)
    vec2 uScreenRes;          // Screen resolution in pixels (width, height)
    vec2 uCardPos;            // Card top-left in screen pixels (x, y)
    float uRadius;            // Corner radius in pixels (e.g. 28.0)
    float uBevelWidth;        // Bevel / meniscus rim width in pixels (e.g. 38.0)
    float uRefractionPixels;  // Max refraction displacement in pixels (e.g. 28.0)
    float uDispersionPixels;  // Prismatic chromatic aberration in pixels (e.g. 4.5)
    float uBulgePixels;       // Center lens bulge displacement in pixels (e.g. 10.0)
    float uSpecular;          // Specular rim intensity (e.g. 0.85)
    float uFrost;             // Frost mix (0.0 = crystal liquid, 1.0 = frosty)
};

layout(binding = 1) uniform sampler2D source;

// Signed distance to a 2D rounded box
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

// Surface normal of the rounded box boundary
vec2 sdRoundedBoxNormal(vec2 p, vec2 b, float r) {
    float eps = 0.5;
    float d = sdRoundedBox(p, b, r);
    float dx = sdRoundedBox(p + vec2(eps, 0.0), b, r) - d;
    float dy = sdRoundedBox(p + vec2(0.0, eps), b, r) - d;
    vec2 n = vec2(dx, dy);
    float l = length(n);
    return l > 0.0001 ? n / l : vec2(0.0);
}

void main() {
    vec2 cardSize = uResolution;
    vec2 p = (qt_TexCoord0 - 0.5) * cardSize; // Center is (0,0) in pixels
    vec2 halfSize = cardSize * 0.5;
    float r = uRadius;

    // Distance from the card perimeter (negative inside, positive outside)
    float dist = sdRoundedBox(p, halfSize, r);

    // Antialiased outer boundary (subpixel smooth cutoff)
    float edgeAlpha = 1.0 - smoothstep(-1.5, 0.5, dist);
    if (edgeAlpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // Distance inward from the perimeter in pixels
    float inwardDist = max(-dist, 0.0);

    // 1. BEVELED MENISCUS REFRACTION (Curvature of the glass rim)
    // The surface tilts dramatically towards the edge inside the bevel rim
    float bevelWidth = max(uBevelWidth, 6.0);
    float tBevel = clamp(inwardDist / bevelWidth, 0.0, 1.0);

    // Smooth sinusoidal slope profile: 1.0 at outer rim -> 0.0 at flat interior
    float meniscusSlope = pow(1.0 - tBevel, 1.8);

    // Surface gradient normal pointing outward towards the edge
    vec2 rimNormal = sdRoundedBoxNormal(p, halfSize, r);

    // 2. CENTER LENS BULGE (Organic convex curvature across the card body)
    vec2 normCoord = p / max(cardSize.x, cardSize.y);
    float centerDist = length(normCoord);
    vec2 bulgeNormal = -normCoord * smoothstep(0.55, 0.0, centerDist);

    // Inward optical bending vector (in pixels)
    // Convex glass bends light rays towards the normal of curvature
    vec2 totalDisplacementPixels = (-rimNormal * (meniscusSlope * uRefractionPixels)) + (bulgeNormal * uBulgePixels);

    // Convert pixel displacement into normalized UV screen coordinates
    vec2 uvDisplacement = totalDisplacementPixels / uScreenRes;
    vec2 dispersionUV = (rimNormal * (meniscusSlope * uDispersionPixels)) / uScreenRes;

    // Screen UV coordinate corresponding to this pixel
    vec2 screenUV = (uCardPos + qt_TexCoord0 * cardSize) / uScreenRes;

    // 3. CHROMATIC DISPERSION (Red, Green, Blue channel splitting)
    vec2 uvR = clamp(screenUV + uvDisplacement - dispersionUV, vec2(0.001), vec2(0.999));
    vec2 uvG = clamp(screenUV + uvDisplacement, vec2(0.001), vec2(0.999));
    vec2 uvB = clamp(screenUV + uvDisplacement + dispersionUV, vec2(0.001), vec2(0.999));

    float colR = texture(source, uvR).r;
    float colG = texture(source, uvG).g;
    float colB = texture(source, uvB).b;
    vec3 refractedColor = vec3(colR, colG, colB);

    // 4. SPECULAR MENISCUS REFLECTION (Fresnel Rim Highlight)
    // Virtual directional light from top-left (-0.5, -0.85, 0.6)
    vec3 lightDir = normalize(vec3(-0.45, -0.85, 0.65));
    // 3D surface normal reconstruction
    float heightZ = sin(tBevel * 1.5707963);
    vec3 normal3D = normalize(vec3(rimNormal * meniscusSlope * 2.2, max(heightZ, 0.15)));
    
    // Specular highlight following the curved meniscus
    float spec = pow(max(dot(normal3D, lightDir), 0.0), 16.0) * uSpecular;
    
    // Sharp specular rim line right at the perimeter edge (1.5px to 3px)
    float rimLine = smoothstep(3.5, 1.0, inwardDist) * smoothstep(0.0, 1.0, inwardDist) * 0.65;
    
    // Top-grazing specular rim (extra sheen on top edges)
    float topSheen = smoothstep(0.2, -0.8, rimNormal.y) * smoothstep(bevelWidth, 0.0, inwardDist) * 0.35;

    // 5. LIQUID GLASS INTERNAL REFLECTANCE & CAUSTIC DEPTH
    // Glass is clear but has subtle luminous depth and internal reflection
    vec3 glassTint = vec3(0.94, 0.96, 1.0);
    vec3 baseGlass = mix(refractedColor * glassTint + vec3(0.02, 0.035, 0.05), refractedColor, 0.4);

    // Composite final color
    vec3 finalColor = baseGlass + vec3(spec * 0.85 + rimLine + topSheen);

    fragColor = vec4(finalColor, edgeAlpha * qt_Opacity);
}
