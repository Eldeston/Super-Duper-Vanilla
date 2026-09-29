#ifndef AURORA_GLSL
#define AURORA_GLSL

#ifndef PI
    #define PI 3.14159265
#endif
#ifndef TAU
    #define TAU 6.28318531
#endif

#ifndef IS_COLD_BIOME_DECLARED
    #define IS_COLD_BIOME_DECLARED
    uniform float isColdBiome;
#endif

#ifndef BIOME_CATEGORY_DECLARED
    #define BIOME_CATEGORY_DECLARED
    uniform int biome_category;
    uniform int biome_precipitation;
#endif

// Aurora vertical color gradient: Pink (top) -> Green (mid) -> Blue (bottom)
// bThick: dynamic thickness of the bottom blue band (~0.10 to 0.22)
// pThick: dynamic onset threshold of the top pink band (~0.72 to 0.84)
vec3 getAuroraColor(in float h, in float bThick, in float pThick){
    const vec3 colDeepBlue = vec3(0.04, 0.22, 0.98);
    const vec3 colCyan     = vec3(0.06, 0.65, 0.95);
    const vec3 colAqua     = vec3(0.08, 0.90, 0.70);
    const vec3 colGreen    = vec3(0.12, 0.98, 0.32);
    const vec3 colViolet   = vec3(0.65, 0.18, 0.82);
    const vec3 colMagenta  = vec3(0.96, 0.18, 0.65);
    const vec3 colRose     = vec3(0.92, 0.12, 0.48);

    // Blue bottom band: h in [0, bThick]
    if(h < bThick * 0.60){
        return colDeepBlue;
    }
    if(h < bThick){
        return mix(colDeepBlue, colCyan, (h - bThick * 0.60) / (bThick * 0.40));
    }
    // Transition from Cyan to Aqua to Green
    float transAqua = bThick + 0.05;
    if(h < transAqua){
        return mix(colCyan, colAqua, (h - bThick) / 0.05);
    }
    float transGreen = bThick + 0.10;
    if(h < transGreen){
        return mix(colAqua, colGreen, (h - transAqua) / 0.05);
    }

    // Green middle zone
    float transViolet = pThick - 0.08;
    if(h < transViolet){
        return colGreen;
    }
    // Transition from Green to Violet to Magenta to Pink
    if(h < pThick){
        return mix(colGreen, colViolet, (h - transViolet) / 0.08);
    }
    float halfPink = pThick + (1.0 - pThick) * 0.5;
    if(h < halfPink){
        return mix(colViolet, colMagenta, (h - pThick) / max(0.01, halfPink - pThick));
    }
    return mix(colMagenta, colRose, (h - halfPink) / max(0.01, 1.0 - halfPink));
}

// Snaking and intersecting dancing wave functions for 5 vertical billboard curtains
float getCurtainWave(in float u, in float h, in float t, in int k){
    // Serpentine wave frequencies producing dramatic winding curves
    float u1 = u * 0.0055;
    float u2 = u * 0.0140;
    float u3 = u * 0.0320;
    float u4 = u * 0.0750;

    float wave = 0.0;
    if(k == 0){
        // Curtain 0: Main centerpiece snaking across the sky
        wave  = sin(u1 + t * 0.22) * 78.0;
        wave += cos(u2 - t * 0.45) * 36.0;
        wave += sin(u3 + t * 0.85 + h * 2.0) * 16.0;
        wave += cos(u4 - t * 1.35 + h * 3.0) * 5.0;
    } else if(k == 1){
        // Curtain 1: Opposing serpentine braid - repeatedly crosses Curtain 0
        wave  = -sin(u1 * 1.10 + t * 0.28 + 0.4) * 82.0;
        wave += cos(u2 * 0.95 + t * 0.50) * 32.0;
        wave += sin(u3 * 1.05 - t * 0.95 + h * 2.2) * 15.0;
        wave += cos(u4 * 1.10 + t * 1.45 + h * 2.8) * 4.5;
    } else if(k == 2){
        // Curtain 2: Cross-weaving ribbon snaking at quarter-phase through the braids
        wave  = cos(u1 * 0.90 - t * 0.32 + 1.2) * 74.0;
        wave += sin(u2 * 1.15 + t * 0.55) * 30.0;
        wave += cos(u3 * 0.95 + t * 1.10 + h * 1.8) * 13.0;
        wave += sin(u4 * 1.05 - t * 1.60 + h * 2.6) * 4.0;
    } else if(k == 3){
        // Curtain 3: Agile tight serpentine ribbon snaking in and out of the center
        wave  = sin(u1 * 1.35 + t * 0.40 + 2.5) * 64.0;
        wave += cos(u2 * 1.25 - t * 0.68) * 26.0;
        wave += sin(u3 * 1.20 + t * 1.25 + h * 2.1) * 12.0;
        wave += cos(u4 * 1.15 - t * 1.75 + h * 2.7) * 4.0;
    } else {
        // Curtain 4: Wide looping serpentine ribbon snaking across the whole group
        wave  = -cos(u1 * 0.80 - t * 0.24 + 1.8) * 86.0;
        wave += sin(u2 * 0.90 + t * 0.42) * 34.0;
        wave += cos(u3 * 1.10 - t * 0.80 + h * 1.9) * 14.0;
        wave += sin(u4 * 0.90 + t * 1.30 + h * 2.5) * 4.5;
    }
    return wave;
}

// Volumetric aurora curtain raymarcher with billboard-style vertical curtains and serpentine intersections
vec3 getVolumetricAurora(in vec3 nEyePlayerPos, in float time){
    // Horizon fade: smoothly zero out near and below the horizon
    if(nEyePlayerPos.y <= 0.035) return vec3(0.0);
    float horizonFade = saturate((nEyePlayerPos.y - 0.035) * 5.0);
    horizonFade = horizonFade * horizonFade * (3.0 - 2.0 * horizonFade);

    // Reference altitude anchored to camera
    float yRef = max(240.0, cameraPosition.y + 40.0);

    // 5 curtains sharing a common flight corridor so large snaking waves intersect repeatedly
    const float curtainAngles[5] = float[5](0.12, -0.08, 0.18, -0.15, 0.05);
    const vec2 curtainOffsets[5] = vec2[5](
        vec2(0.0, 0.0),     // Curtain 0: Centerpiece
        vec2(15.0, -10.0),  // Curtain 1: Braided with Curtain 0
        vec2(-15.0, 15.0),  // Curtain 2: Cross ribbon
        vec2(5.0, -25.0),   // Curtain 3: Agile inner snake
        vec2(-20.0, 25.0)   // Curtain 4: Wide outer serpentine sweep
    );
    const float curtainWeights[5] = float[5](1.00, 0.88, 0.82, 0.85, 0.78);

    // Diverse base altitudes and vertical height spans for each curtain
    const float curtainBaseOffsets[5] = float[5](20.0, 10.0, 35.0, 5.0, 30.0);
    const float curtainRanges[5]      = float[5](220.0, 190.0, 170.0, 160.0, 205.0);

    // Global altitude bounds for the raymarching volume
    float yGlobalBase = yRef + 5.0;
    float yGlobalTop  = yRef + 245.0;

    // Ray distance range inside the aurora altitude layer
    float tStart = max(0.0, (yGlobalBase - cameraPosition.y) / nEyePlayerPos.y);
    float tEnd   = (yGlobalTop - cameraPosition.y) / nEyePlayerPos.y;

    // Beyond max visibility distance, return nothing
    const float maxDist = 2800.0;
    if(tStart >= maxDist) return vec3(0.0);
    tEnd = min(tEnd, maxDist);

    float tSpan = tEnd - tStart;
    if(tSpan <= 0.0) return vec3(0.0);

    // Billboard block size (meters per square pixel on the vertical curtain)
    const float BLOCK_SIZE = 10.0;

    float tAnim = time * 0.35;

    // Dither along the ray to prevent banding
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

    // 40 steps along the 3D view ray ensures all intersecting curves are captured
    const int STEPS = 40;
    float dt = tSpan / float(STEPS);
    float stepNorm = (dt / BLOCK_SIZE) * 0.10;
    float captureWidth = max(BLOCK_SIZE * 0.90, dt * 0.65);

    vec3 totalAurora = vec3(0.0);

    for(int s = 0; s < STEPS; s++){
        float t = tStart + (float(s) + dither) * dt;
        if(t > tEnd) break;

        vec3 p = cameraPosition + nEyePlayerPos * t;
        float Y = p.y;

        // Distance attenuation
        float distFade = saturate(1.0 - t / maxDist);
        if(distFade <= 0.0) continue;
        distFade *= distFade;

        // Evaluate all 5 curtains at this 3D position
        for(int k = 0; k < 5; k++){
            float yBaseK = yRef + curtainBaseOffsets[k];
            float yRangeK = curtainRanges[k];
            float yRel = Y - yBaseK;
            if(yRel < 0.0 || yRel >= yRangeK) continue;

            float numRowsK = floor(yRangeK / BLOCK_SIZE);
            float row = floor(yRel / BLOCK_SIZE);
            if(row < 0.0 || row >= numRowsK) continue;
            float hRow = (row + 0.5) / numRowsK;

            // Height envelope: crisp bottom onset, smooth top atmospheric fade
            float heightEnv = smoothstep(0.0, 0.06, hRow) * smoothstep(1.0, 0.72, hRow);

            vec2 relPos = p.xz - curtainOffsets[k];
            vec2 rotPos = rot2D(curtainAngles[k]) * relPos;
            float u = rotPos.x;
            float v = rotPos.y;

            // Horizontal billboard column index along the curtain
            float col = floor(u / BLOCK_SIZE);
            float uCenter = (col + 0.5) * BLOCK_SIZE;

            // Billboard curtain spine position for this column
            float vSpine = getCurtainWave(uCenter, hRow, tAnim, k);
            float distToBillboard = abs(v - vSpine);

            // One layer thick vertical billboard curtain with adaptive capture radius
            float billboardMask = saturate((captureWidth - distToBillboard) / (BLOCK_SIZE * 0.40));
            if(billboardMask <= 0.0) continue;

            // Variable dynamic thickness: blue at bottom (~0.10 to 0.22) and thicker pink at top (~0.16 to 0.28)
            float blueThick = 0.16 + 0.06 * sin(uCenter * 0.007 + tAnim * 0.45 + float(k) * 1.7);
            float pinkThick = 0.78 - 0.06 * cos(uCenter * 0.006 - tAnim * 0.38 + float(k) * 2.3);

            // Color for this vertical billboard square
            vec3 tileColor = getAuroraColor(hRow, blueThick, pinkThick);

            // Individual vertical billboard square tile hash (col, row)
            float tileHash = fract(sin(dot(vec2(col, row), vec2(12.9898, 78.233)) + float(k) * 43.12) * 43758.5453);
            float filament = 0.72 + 0.28 * sin(uCenter * 0.040 + tAnim * 0.60 + tileHash * 6.28);
            if(tileHash > 0.80) filament *= 1.35;

            float contrib = billboardMask * filament * curtainWeights[k] * heightEnv * distFade * stepNorm;
            totalAurora += tileColor * contrib;
        }
    }

    return totalAurora * (horizonFade * 0.80);
}

#endif // AURORA_GLSL
