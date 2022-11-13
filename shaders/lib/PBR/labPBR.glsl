// Get normal texture
uniform sampler2D normals;
// Get specular texture
uniform sampler2D specular;

// For Optifine to detect this option
#ifdef PARALLAX_SHADOWS
#endif

#ifdef PARALLAX_OCCLUSION
    vec2 getParallaxOffset(in vec3 dirT){ return dirT.xy * (PARALLAX_DEPTH / dirT.z); }

    vec2 parallaxUv(in vec2 startUv, in vec2 endUv, out vec3 currPos){
        float stepSize = 1.0 / PARALLAX_STEPS;
        endUv *= stepSize * PARALLAX_DEPTH;

        float texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
        float traceDepth = 1.0;

        for(int i = 0; i < PARALLAX_STEPS; i++){
            if(texDepth >= traceDepth) break;
            startUv += endUv;
            traceDepth -= stepSize;
            texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
        }

        currPos = vec3(startUv - endUv, traceDepth + stepSize);
        return startUv;
    }

    #if defined PARALLAX_SHADOWS && defined WORLD_LIGHT
        float parallaxShadow(in vec3 currPos, in vec2 lightDir) {
            float stepSize = 1.0 / PARALLAX_SHD_STEPS;
            vec2 stepOffset = stepSize * lightDir;

            float traceDepth = currPos.z;
            vec2 traceUv = currPos.xy;

            for(int i = int(traceDepth * PARALLAX_SHD_STEPS); i < PARALLAX_SHD_STEPS; i++){
                if(texture2DGradARB(normals, fract(traceUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a >= traceDepth) return pow(i * stepSize, 16.0);
                // if(texture2DGradARB(normals, fract(traceUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a >= traceDepth) return 0.0;
                traceUv += stepOffset;
                traceDepth += stepSize;
            }

            return 1.0;
        }
    #endif

    #ifdef SLOPE_NORMALS
        uniform ivec2 atlasSize;

        vec2 getSlopeNormals(in vec3 viewT, in vec2 texUv, in float traceDepth){
            vec2 texPixSize = 1.0 / atlasSize;

            vec2 texSnapped = floor(texUv * atlasSize) * texPixSize;
            vec2 texOffset = texUv - texSnapped - texPixSize * 0.5;
            vec2 stepSign = sign(-viewT.xy);

            vec2 texX = texSnapped + vec2(texPixSize.x * stepSign.x, 0);
            float heightX = texture2DGradARB(normals, texX, dcdx, dcdy).a;
            bool hasX = traceDepth > heightX && sign(texOffset.x) == stepSign.x;

            vec2 texY = texSnapped + vec2(0, texPixSize.y * stepSign.y);
            float heightY = texture2DGradARB(normals, texY, dcdx, dcdy).a;
            bool hasY = traceDepth > heightY && sign(texOffset.y) == stepSign.y;

            if(abs(texOffset.x) < abs(texOffset.y)){
                if(hasY) return vec2(0, stepSign.y);
                if(hasX) return vec2(stepSign.x, 0);
            }else{
                if(hasX) return vec2(stepSign.x, 0);
                if(hasY) return vec2(0, stepSign.y);
            }

            float s = step(abs(viewT.y), abs(viewT.x));
            return vec2(1.0 - s, s) * stepSign;
        }
    #endif
#endif

// The lab PBR standard 1.3
void getPBR(inout structPBR material, in int id){
    vec2 texUv = texCoord;

    // Exclude signs and floating texts. We'll also include water and lava in the meantime.
    bool hasNormal = id != 10000 && id != 10001 && abs(sumOf(texture2DGradARB(normals, texCoord, dcdx, dcdy).xy)) >= 0.01;

    #ifdef PARALLAX_OCCLUSION
        vec3 viewDir = -vertexPos.xyz * TBN;

        vec3 currPos;

        if(hasNormal) texUv = fract(parallaxUv(vTexCoord, viewDir.xy / -viewDir.z, currPos)) * vTexCoordScale + vTexCoordPos;
    #endif

    // Assign albedo
    material.albedo = texture2DGradARB(texture, texUv, dcdx, dcdy);

    #if !(defined ENTITIES || defined ENTITIES_GLOWING)
        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;
    #endif

    // Assign default normal map
    material.normal = TBN[2];

    // Get raw textures
    vec4 normalAOH = texture2DGradARB(normals, texUv, dcdx, dcdy);
    vec4 SRPSSE = texture2DGradARB(specular, texUv, dcdx, dcdy);

    // Decode and extract the materials
    // Extract normals
    vec3 normalMap = vec3(normalAOH.xy * 2.0 - 1.0, 0);
    // Get the z normal direction and clamp to 0.0 (NaN fix)
    normalMap.z = max(0.0, sqrt(1.0 - dot(normalMap.xy, normalMap.xy)));

    // Assign porosity
    material.porosity = SRPSSE.b < 0.252 ? SRPSSE.b * 3.984 : 0.0;

    // Assign SS
    material.ss = SRPSSE.b > 0.252 ? (SRPSSE.b - 0.2509804) * 1.3350785 : 0.0;

    // Assign smoothness
    material.smoothness = min(SRPSSE.r, 0.96);

    // Assign reflectance
    material.metallic = SRPSSE.g;

    // Assign emissive
    material.emissive = SRPSSE.a != 1 ? SRPSSE.a : 0.0;

    // Assign ambient
    #ifdef TERRAIN
        // Apply vanilla AO with it in terrain
        material.ambient = vertexAO * normalAOH.b;
    #else
        // For others, don't use vanilla AO
        material.ambient = normalAOH.b;
    #endif

    #ifdef TERRAIN
        // If lava and fire
        if(id == 10001 || id == 10002) material.emissive = 1.0;

        // Foliage and corals
        if((id >= 10003 && id <= 10014) || id == 10033 || id == 10036) material.ss = 1.0;
    #endif

    #ifdef WATER
        // If water
        if(id == 10000){
            material.smoothness = 0.96;
            material.metallic = 0.02;

            #ifdef WATER_FLAT
                material.albedo.rgb = vec3(0.8);
            #endif
        }
            
        // Nether portal
        if(id == 10017){
            material.smoothness = 0.96;
            material.metallic = 0.04;
            material.emissive = maxOf(material.albedo.rgb);
        }
    #endif

    #if defined ENTITIES || defined ENTITIES_GLOWING
        // Experience orbs, glowing item frames, and fireballs
        if(id == 10130 || id == 10131) material.emissive = cubed(sumOf(material.albedo.rgb) * 0.33333333);
    #endif

    // Ambient occlusion fix
    #if defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER
        if(id <= 0) material.ambient = 1.0;
    #endif

    #ifdef BLOCK
        if(id == 10018) material.ambient = 1.0;
    #endif

    // Get parallax shadows
    material.parallaxShd = 1.0;

    #ifdef PARALLAX_OCCLUSION
        if(hasNormal){
            #ifdef SLOPE_NORMALS
                if(texture2DGradARB(normals, texUv, dcdx, dcdy).a > currPos.z) normalMap = vec3(getSlopeNormals(-viewDir, texUv, currPos.z), 0);
            #endif

            #if defined PARALLAX_SHADOWS && defined WORLD_LIGHT
                if(dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) > 0.001)
                    material.parallaxShd = parallaxShadow(currPos, getParallaxOffset(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) * TBN));
                else material.parallaxShd = material.ss;
            #endif
        }
    #endif

    // Assign normal
    if(hasNormal) material.normal = TBN * fastNormalize(normalMap);

    // Calculate normal strength
    material.normal = mix(TBN[2], material.normal, NORMAL_STRENGTH);

    #if WHITE_MODE == 0
        material.albedo.rgb *= vertexColor;
    #elif WHITE_MODE == 1
        material.albedo.rgb = vec3(1);
    #elif WHITE_MODE == 2
        material.albedo.rgb = vec3(0);
    #elif WHITE_MODE == 3
        material.albedo.rgb = vertexColor;
    #endif
}