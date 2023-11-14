// Get normal texture
uniform sampler2D normals;
// Get specular texture
uniform sampler2D specular;

// Texture coordinate derivatives
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

#ifdef PARALLAX_OCCLUSION
    vec2 getParallaxOffset(in vec3 dirT){ return dirT.xy * (PARALLAX_DEPTH / dirT.z); }

    vec2 parallaxUv(in vec2 startUv, in vec2 endUv, out vec3 currPos){
        const float stepSize = 1.0 / PARALLAX_STEPS;
        endUv *= stepSize * PARALLAX_DEPTH;

        float texDepth = textureGrad(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
        float traceDepth = 1.0;

        for(int i = 0; i < PARALLAX_STEPS; i++){
            if(texDepth >= traceDepth) break;
            startUv += endUv;
            traceDepth -= stepSize;
            texDepth = textureGrad(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
        }

        currPos = vec3(startUv - endUv, traceDepth + stepSize);
        return startUv;
    }

    #if defined PARALLAX_SHADOW && defined WORLD_LIGHT
        float parallaxShadow(in vec3 currPos, in vec2 lightDir) {
            const float stepSize = 1.0 / PARALLAX_SHADOW_STEPS;
            vec2 stepOffset = stepSize * lightDir;

            float traceDepth = currPos.z;
            vec2 traceUv = currPos.xy;
            for(int i = int(traceDepth * PARALLAX_SHADOW_STEPS); i < PARALLAX_SHADOW_STEPS; i++){
                if(textureGrad(normals, fract(traceUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a >= traceDepth) return exp2(i - PARALLAX_SHADOW_STEPS);
                traceDepth += stepSize;
                traceUv += stepOffset;
            }

            return 1.0;
        }
    #endif

    #ifdef SLOPE_NORMALS
        uniform ivec2 atlasSize;

        // Slope normals by @null511
        vec2 getSlopeNormals(in vec3 viewT, in vec2 texUv, in float traceDepth){
            vec2 texPixSize = 1.0 / atlasSize;

            vec2 texSnapped = floor(texUv * atlasSize) * texPixSize;
            vec2 texOffset = texUv - texSnapped - texPixSize * 0.5;
            vec2 stepSign = sign(-viewT.xy);

            vec2 texX = vec2(texSnapped.x + texPixSize.x * stepSign.x, texSnapped.y);
            float heightX = textureGrad(normals, texX, dcdx, dcdy).a;
            bool hasX = traceDepth > heightX && sign(texOffset.x) == stepSign.x;

            vec2 texY = vec2(texSnapped.x, texSnapped.y + texPixSize.y * stepSign.y);
            float heightY = textureGrad(normals, texY, dcdx, dcdy).a;
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
void getPBR(inout dataPBR material, in int id){
    vec2 texUv = texCoord;

    // Exclude signs and floating texts. We'll also include water and lava in the meantime.
    // This bool checks if Optifine is using the proper fallback for normal maps and ao
    bool hasFallback = id != 11100 && id != 11102 && id != 12101 && sumOf(textureGrad(normals, texCoord, dcdx, dcdy).xy) != 0;

    #ifdef PARALLAX_OCCLUSION
        vec3 viewDir = -vertexFeetPlayerPos.xyz * TBN;

        vec3 currPos;

        if(hasFallback) texUv = fract(parallaxUv(vTexCoord, viewDir.xy / -viewDir.z, currPos)) * vTexCoordScale + vTexCoordPos;
    #endif

    // Assign albedo
    material.albedo = textureGrad(tex, texUv, dcdx, dcdy);

    // Alpha test, discard and return immediately
    if(material.albedo.a < ALPHA_THRESHOLD){ discard; return; }

    // Assign default normal map
    material.normal = TBN[2];

    // Get raw textures
    vec3 normalAOH = textureGrad(normals, texUv, dcdx, dcdy).xyz;
    vec4 SRPSSE = textureGrad(specular, texUv, dcdx, dcdy);

    // Decode and extract the materials
    // Extract normals
    vec3 normalMap = vec3(normalAOH.xy * 2.0 - 1.0, 0);

    // Get the dot of XY
    float normalXY = lengthSquared(normalMap.xy);
    // If length is less than one, calculate Z
    if(normalXY < 1) normalMap.z = sqrt(1.0 - normalXY);
    // If length is more than one, normalize XY
    else normalMap.xy *= inversesqrt(normalXY);

    // Assign reflectance
    material.metallic = SRPSSE.g;

    // Assign smoothness
    material.smoothness = min(SRPSSE.r, 0.96);

    // Assign emissive
    material.emissive = SRPSSE.a != 1 ? SRPSSE.a : 0.0;

    // Assign porosity
    material.porosity = SRPSSE.b < 0.252 ? SRPSSE.b * 3.984 : 0.0;

    // Assign SS
    material.ss = SRPSSE.b > 0.252 ? (SRPSSE.b - 0.2509804) * 1.3350785 : 0.0;

    // Assign ambient occlusion
    #if defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER
        // Ambient occlusion fallback fix
        material.ambient = id <= 0 ? 1.0 : normalAOH.b;
    #elif defined BLOCK
        // Ambient occlusion fallback fix
        material.ambient = id == 12001 ? 1.0 : normalAOH.b;
    #elif defined TERRAIN
        // Apply vanilla AO with it in terrain
        material.ambient = vertexAO * normalAOH.b;
    #else
        // Apply no AO for water
        material.ambient = normalAOH.b;
    #endif

    #ifdef TERRAIN
        // If lava and fire
        if(id == 11100 || id == 12101) material.emissive = 1.0;

        // Foliage and corals
        else if((id >= 10000 && id <= 10800) || id == 10900 || id == 11101 || id == 12200) material.ss = 1.0;
    #endif

    #ifdef WATER
        // If water
        if(id == 11102){
            material.metallic = 0.02;
            material.smoothness = 0.96;

            #ifdef WATER_FLAT
                material.albedo.rgb = vec3(0.8);
            #endif
        }
            
        // Nether portal
        else if(id == 12100){
            material.metallic = 0.04;
            material.smoothness = 0.96;
            material.emissive = maxOf(material.albedo.rgb);
        }
    #endif

    #if defined ENTITIES || defined ENTITIES_GLOWING
        // Basic whole entity emission
        if(id == 10130) material.emissive = cubed(sumOf(material.albedo.rgb) * 0.33333333);

        // End crystal
        else if(id == 10131) material.emissive = float(material.albedo.r > sumOf(material.albedo.gb) * 0.5);

        // Charged creeper
        else if(id == 10132) material.emissive = float(material.albedo.b > material.albedo.g);
    #endif

    #if COLOR_MODE == 0
        material.albedo.rgb *= vertexColor;
    #elif COLOR_MODE == 1
        material.albedo.rgb = vec3(1);
    #elif COLOR_MODE == 2
        material.albedo.rgb = vec3(0);
    #elif COLOR_MODE == 3
        material.albedo.rgb = vertexColor;
    #endif

    // Get parallax shadows
    material.parallaxShd = 1.0;

    #ifdef PARALLAX_OCCLUSION
        if(hasFallback){
            #ifdef SLOPE_NORMALS
                if(textureGrad(normals, texUv, dcdx, dcdy).a > currPos.z) normalMap = vec3(getSlopeNormals(-viewDir, texUv, currPos.z), 0);
            #endif

            #if defined PARALLAX_SHADOW && defined WORLD_LIGHT
                if(dot(TBN[2], vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) > 0.001)
                    material.parallaxShd = parallaxShadow(currPos, getParallaxOffset(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) * TBN));
                else material.parallaxShd = material.ss;
            #endif
        }
    #endif

    // Assign normal and calculate normal strength
    if(hasFallback) material.normal = mix(TBN[2], TBN * normalMap, NORMAL_STRENGTH);
}