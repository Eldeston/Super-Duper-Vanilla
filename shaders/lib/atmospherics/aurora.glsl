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
    uniform float smoothBiomeTemp;
#endif

#ifndef BIOME_CATEGORY_DECLARED
    #define BIOME_CATEGORY_DECLARED
    uniform int biome_category;
    uniform int biome_precipitation;
#endif

// Aurora vertical color gradient: Pink (top) -> Green (mid) -> Blue (bottom)
// Vivid glowing HDR emission palette: rich emerald green, electric cyan/blue base, vibrant magenta/rose crown
vec3 getAuroraColor(in float h, in float bThick, in float pThick){
    const vec3 colDeepBlue = vec3(0.04, 0.28, 1.20);
    const vec3 colCyan     = vec3(0.06, 0.85, 1.10);
    const vec3 colAqua     = vec3(0.08, 1.15, 0.75);
    const vec3 colGreen    = vec3(0.12, 1.30, 0.38);
    const vec3 colViolet   = vec3(0.75, 0.18, 0.95);
    const vec3 colMagenta  = vec3(1.20, 0.20, 0.80);
    const vec3 colRose     = vec3(1.10, 0.14, 0.55);

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
    float u1 = u * 0.0055;
    float u2 = u * 0.0140;
    float u3 = u * 0.0320;
    float u4 = u * 0.0750;

    float wave = 0.0;
    if(k == 0){
        // Curtain 0: Main centerpiece snaking across the zenith
        wave  = sin(u1 + t * 0.22) * 75.0;
        wave += cos(u2 - t * 0.45) * 35.0;
        wave += sin(u3 + t * 0.85 + h * 2.0) * 16.0;
        wave += cos(u4 - t * 1.35 + h * 3.0) * 5.0;
    } else if(k == 1){
        // Curtain 1: Opposing serpentine braid - repeatedly crosses Curtain 0
        wave  = -sin(u1 * 1.10 + t * 0.28 + 0.4) * 80.0;
        wave += cos(u2 * 0.95 + t * 0.50) * 32.0;
        wave += sin(u3 * 1.05 - t * 0.95 + h * 2.2) * 15.0;
        wave += cos(u4 * 1.10 + t * 1.45 + h * 2.8) * 4.5;
    } else if(k == 2){
        // Curtain 2: Cross-weaving ribbon snaking through the braids
        wave  = cos(u1 * 0.90 - t * 0.32 + 1.2) * 72.0;
        wave += sin(u2 * 1.15 + t * 0.55) * 30.0;
        wave += cos(u3 * 0.95 + t * 1.10 + h * 1.8) * 13.0;
        wave += sin(u4 * 1.05 - t * 1.60 + h * 2.6) * 4.0;
    } else if(k == 3){
        // Curtain 3: Agile tight serpentine ribbon
        wave  = sin(u1 * 1.35 + t * 0.40 + 2.5) * 64.0;
        wave += cos(u2 * 1.25 - t * 0.68) * 26.0;
        wave += sin(u3 * 1.20 + t * 1.25 + h * 2.1) * 12.0;
        wave += cos(u4 * 1.15 - t * 1.75 + h * 2.7) * 4.0;
    } else {
        // Curtain 4: Wide looping serpentine ribbon
        wave  = -cos(u1 * 0.80 - t * 0.24 + 1.8) * 84.0;
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

    // Temperature index response: auroras are brightest & overhead in freezing biomes (<= 0.0),
    // and become progressively fainter and further away as temperature rises (taiga ~0.25, cold ocean ~0.42)
    float tWarm = saturate((0.55 - smoothBiomeTemp) / 0.55);
    float tempIntensity = tWarm * tWarm * (3.0 - 2.0 * tWarm);
    if(tempIntensity <= 0.001) return vec3(0.0);

    float warmDistShift = saturate(max(0.0, smoothBiomeTemp) / 0.48) * 160.0;

    // Reference altitude: anchored nearer to player, slightly higher if distant
    float yRef = max(170.0 + warmDistShift * 0.20, cameraPosition.y + 60.0);

    // 5 distinct curtains positioned relative to the player's sky dome
    // Shifting along -Z (northward) with temperature so they appear further away on the horizon
    const float curtainAngles[5] = float[5](0.14, -0.10, 0.22, -0.18, 0.06);
    vec2 curtainOffsets[5] = vec2[5](
        vec2(0.0, -warmDistShift),
        vec2(35.0, -25.0 - warmDistShift),
        vec2(-40.0, 35.0 - warmDistShift * 0.8),
        vec2(20.0, -75.0 - warmDistShift),
        vec2(-60.0, 75.0 - warmDistShift * 0.8)
    );
    mat2 rotCurtains[5] = mat2[5](
        rot2D(0.14), rot2D(-0.10), rot2D(0.22), rot2D(-0.18), rot2D(0.06)
    );
    const float curtainWeights[5] = float[5](1.00, 0.88, 0.82, 0.85, 0.78);

    // Towering vertical height spans (165 to 210 blocks tall) for grand presence
    const float curtainBaseOffsets[5] = float[5](15.0, 5.0, 25.0, 0.0, 20.0);
    const float curtainRanges[5]      = float[5](210.0, 185.0, 175.0, 165.0, 195.0);
    const float numRowsK[5]           = float[5](21.0, 18.0, 17.0, 16.0, 19.0);
    const float invNumRowsK[5]        = float[5](1.0 / 21.0, 1.0 / 18.0, 1.0 / 17.0, 1.0 / 16.0, 1.0 / 19.0);

    // Global altitude bounds for the raymarching volume
    float yGlobalBase = yRef + 5.0;
    float yGlobalTop  = yRef + 230.0;

    // Ray distance range inside the aurora altitude layer
    float rcpEyeY = 1.0 / nEyePlayerPos.y;
    float tStart = max(0.0, (yGlobalBase - cameraPosition.y) * rcpEyeY);
    float tEnd   = (yGlobalTop - cameraPosition.y) * rcpEyeY;

    // Beyond max visibility distance, return nothing
    const float maxDist = 2600.0;
    const float invMaxDist = 1.0 / maxDist;
    if(tStart >= maxDist) return vec3(0.0);
    tEnd = min(tEnd, maxDist);

    float tSpan = tEnd - tStart;
    if(tSpan <= 0.0) return vec3(0.0);

    // Billboard block size (meters per square pixel on the vertical curtain)
    const float BLOCK_SIZE = 10.0;
    const float invBlockSize = 1.0 / BLOCK_SIZE;

    float tAnim = time * 0.35;

    // Dither along the ray to prevent banding
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

    const int STEPS = 36;
    float dt = tSpan * (1.0 / float(STEPS));
    float stepNorm = (dt * invBlockSize) * 0.085;
    float captureWidth = max(BLOCK_SIZE * 0.90, dt * 0.65);

    vec3 totalAurora = vec3(0.0);

    for(int s = 0; s < STEPS; s++){
        float t = tStart + (float(s) + dither) * dt;
        if(t > tEnd) break;

        // Position relative to player: curtains are centered right overhead
        vec2 playerRelXZ = nEyePlayerPos.xz * t;
        float Y = cameraPosition.y + nEyePlayerPos.y * t;

        // Smooth distance attenuation
        float distFade = saturate(1.0 - t * invMaxDist);
        if(distFade <= 0.0) continue;
        distFade *= distFade;

        // Evaluate all 5 curtains at this 3D position
        for(int k = 0; k < 5; k++){
            float yBaseK = yRef + curtainBaseOffsets[k];
            float yRangeK = curtainRanges[k];
            float yRel = Y - yBaseK;
            if(yRel < 0.0 || yRel >= yRangeK) continue;

            float row = floor(yRel * invBlockSize);
            if(row < 0.0 || row >= numRowsK[k]) continue;
            float hRow = (row + 0.5) * invNumRowsK[k];

            // Height envelope: crisp bottom onset, smooth top atmospheric fade
            float heightEnv = smoothstep(0.0, 0.06, hRow) * smoothstep(1.0, 0.70, hRow);

            vec2 relPos = playerRelXZ - curtainOffsets[k];
            vec2 rotPos = rotCurtains[k] * relPos;
            float u = rotPos.x;
            float v = rotPos.y;

            // Horizontal billboard column index along the curtain
            float col = floor(u * invBlockSize);
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

            // Vivid, luminous HDR color for this vertical billboard square
            vec3 tileColor = getAuroraColor(hRow, blueThick, pinkThick);

            // Individual vertical billboard square tile hash (col, row)
            float tileHash = fract(sin(dot(vec2(col, row), vec2(12.9898, 78.233)) + float(k) * 43.12) * 43758.5453);
            float filament = 0.75 + 0.35 * sin(uCenter * 0.040 + tAnim * 0.60 + tileHash * 6.28);
            if(tileHash > 0.80) filament *= 1.35;

            float contrib = billboardMask * filament * curtainWeights[k] * heightEnv * distFade * stepNorm;
            totalAurora += tileColor * contrib;
        }
    }

    return totalAurora * (horizonFade * (0.90 * tempIntensity));
}

#endif // AURORA_GLSL
