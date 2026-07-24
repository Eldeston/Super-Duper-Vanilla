const uint rayTraceSteps = uint(RAYTRACER_STEPS);
const uint rayTraceBiSteps = uint(RAYTRACER_BISTEPS);

// Binary refinement to improve sampled quality by stepping back and forth until it is closer to the actual result
vec2 binaryRefinement(in vec3 screenRayPos, in vec3 screenRayDir, in float sampledDepth, in bool intersection){
    // Reuse stored sampled depth and intersection to use 1 less depth sample
    for(uint i = 1u; i <= rayTraceBiSteps; i++){
        // Refine ray direction
        screenRayDir *= 0.5;
        screenRayPos += intersection ? -screenRayDir : screenRayDir;

        // Return early if we're on the last iteration
        if(i == rayTraceBiSteps) return screenRayPos.xy;

        // Get current texture depth
        sampledDepth = getDepth(depthtex0, ivec2(screenRayPos.xy), 0);
        // Check intersection
        intersection = sampledDepth <= screenRayPos.z;
    }

    // Alas, the ray has reached the end of its journey :,)
    return screenRayPos.xy;
}

// This raytracer is stupid fast I swear...

// With the help of @Lipesto the goat on ShaderLABs
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// Basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
    // Fix for the blob when player is near a surface. From Bálint#1673
    if(rayDir.z > -viewPos.z) return vec3(0);

    // Get screenspace ray direction
    vec3 screenRayDir = getScreenPos(gbufferProjection, viewPos + rayDir) - screenPos;

    // This code preventsoversampling/undersampling by clipping the ray to screen
    screenRayDir *= minOf((step(vec2(0), screenRayDir.xy) - screenPos.xy) / screenRayDir.xy);

    // Calculate ray length and normalize ray direction
    float rayLength = max(abs(screenRayDir.x), abs(screenRayDir.y)) * rayTraceSteps;
    screenRayDir /= rayLength;

    // Scale to screen size
    screenRayDir.xy *= vec2(viewWidth, viewHeight);

    // Apply dithering
    vec3 screenRayPos = vec3(gl_FragCoord.xy, screenPos.z) + screenRayDir * dither;

    // Keep track of depth
    float sampledDepth = 0.0;
    // Keep track of intersections
    bool intersection = false;
    // Use raylength to determine the step count
    uint raySteps = uint(rayLength);

    // ULTRA FAST RAT RACING!!!111!!1!
    // https://www.youtube.com/watch?v=atuFSv2bLa8
    for(uint i = 0u; i < raySteps; i++){
        // We continue ray tracing
        screenRayPos += screenRayDir;

        // If current pos is out of bounds, exit immediately
        if(screenRayPos.x < 0 || screenRayPos.y < 0 || screenRayPos.x > viewWidth || screenRayPos.y > viewHeight) return vec3(0);

        // Get current texture depth
        sampledDepth = getDepth(depthtex0, ivec2(screenRayPos.xy), 0);

        // If hand return immediately
        if(sampledDepth <= 0.56) return vec3(0);

        // Check intersection
        intersection = sampledDepth <= screenRayPos.z;

        // If intersection
        if(intersection) break;
    }

    // If sky or no intersection has been found return immediately
    if(sampledDepth == 1 || !intersection) return vec3(0);

    // Do binary refinement
    #if RAYTRACER_BISTEPS != 0
        return vec3(binaryRefinement(screenRayPos, screenRayDir, sampledDepth, intersection), 1);
    #else
        return vec3(screenRayPos.xy, 1);
    #endif
}