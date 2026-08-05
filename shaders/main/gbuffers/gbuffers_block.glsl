/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, End portal, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out mat3 TBN;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec3 vertexColor;
    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    attribute vec4 at_tangent;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = lightMapCoord(gl_MultiTexCoord1.xy);
        #endif

        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);
        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Calculate TBN matrix
        TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal) * sign(at_tangent.w), vertexNormal));

        #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;

            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3
    
    flat in mat3 TBN;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int blockEntityId;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform float fragmentFrameTime;

    uniform float near;

    uniform sampler2D depthtex0;
    uniform sampler2D gtexture;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdDistort.glsl"
            #include "/lib/lighting/shdSample.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/integratedPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    // Dimensional Doors portal helpers (adapted from vanilla end portal)
    mat2 mat2_rotate_z_portal(float angle) {
        float s = sin(angle);
        float c = cos(angle);
        return mat2(c, s, -s, c);
    }

    mat4 end_portal_layer_dd(float layer, float time) {
        mat4 translate = mat4(
            1.0, 0.0, 0.0, 17.0 / layer,
            0.0, 1.0, 0.0, (2.0 + layer / 1.5) * (time * 0.001),
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        );

        mat2 rotate = mat2_rotate_z_portal(radians((layer * layer * 4321.0 + layer * 9.0) * 1.0));

        mat2 scale = mat2(4.5 - layer / 4.0);

        const mat4 SCALE_TRANSLATE = mat4(
            1.0, 0.0, 0.0, 0.5,
            0.0, 1.0, 0.0, 0.5,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        );

        return mat4(scale * rotate) * translate * SCALE_TRANSLATE;
    }

    float getEndStarField(in vec2 uv, in float time){
        return textureLod(gtexture, vec2(uv.x, uv.y + time) * 0.125, 0).r + textureLod(gtexture, vec2(uv.x - uv.y, uv.y + uv.x + time) * 0.125, 0).r;
    }

    void main(){
        // Dimensional Doors portal, credits to Kawwabi
        if(blockEntityId == 13201){
            // Build UV coordinates from world position projected onto the portal face
            vec3 portalUv = vec3(vertexWorldPos.zy * TBN[2].x + vertexWorldPos.xz * TBN[2].y + vertexWorldPos.xy * TBN[2].z, 1.0);

            // Color palette for Dimensional Doors
            const vec3[] PORTAL_COLORS = vec3[](
                vec3(0.022087, 0.098399, 0.110818),
                vec3(0.011892, 0.095924, 0.089485),
                vec3(0.027636, 0.101689, 0.100326),
                vec3(0.046564, 0.109883, 0.114838),
                vec3(0.064901, 0.117696, 0.097189),
                vec3(0.063761, 0.086895, 0.123646),
                vec3(0.084817, 0.111994, 0.166380),
                vec3(0.097489, 0.154120, 0.091064),
                vec3(0.106152, 0.131144, 0.195191),
                vec3(0.097721, 0.110188, 0.187229),
                vec3(0.133516, 0.138278, 0.148582),
                vec3(0.070006, 0.243332, 0.235792),
                vec3(0.196766, 0.142899, 0.214696),
                vec3(0.047281, 0.315338, 0.321970),
                vec3(0.204675, 0.390010, 0.302066),
                vec3(0.080955, 0.314821, 0.661491)
            );

            // First layer: base texture (zoom in for less tiling)
            vec3 color = textureLod(gtexture, portalUv.xy * 0.25, 0).rgb * PORTAL_COLORS[0];

            // Additional layers with transforms
            for (int i = 0; i < 16; i++) {
                vec4 transformedUv = vec4(portalUv.xy * 0.25, 0.0, 1.0) * end_portal_layer_dd(float(i + 1), fragmentFrameTime);
                vec3 layerColor = textureLod(gtexture, transformedUv.xy / transformedUv.w, 0).rgb;
                color += layerColor * PORTAL_COLORS[min(i, 15)];
            }

            // Normalize by total layer count to prevent over-brightening
            color /= 13.6;

            // Outer glow handled by bloom post-processing
            vec3 finalCol = color * EMISSIVE_INTENSITY * vertexColor.rgb;

            sceneColOut = vec4(toLinear(finalCol), 1);
            normalDataOut = vec3(0);
            albedoDataOut = toLinear(finalCol);
            materialDataOut = vec3(0, 0, 0.5);

            return;
        }

        // End portal
        if(blockEntityId == 12000){
            // Get portal depth
            float blockDepth = near / (1.0 - gl_FragCoord.z) - near / (1.0 - getDepth(depthtex0, ivec2(gl_FragCoord.xy), 0));

            // Get start pos
            vec2 startPos = vertexWorldPos.zy * TBN[2].x + vertexWorldPos.xz * TBN[2].y + vertexWorldPos.xy * TBN[2].z;

            // Get end pos
            vec3 endPos = vertexFeetPlayerPos.zyx * TBN[2].x + vertexFeetPlayerPos.xzy * TBN[2].y + vertexFeetPlayerPos.xyz * TBN[2].z;
            endPos.xy /= endPos.z;
            
            // End star uv
            float starSpeed = fragmentFrameTime * 0.0625;

            float endStarField = getEndStarField(startPos, starSpeed);
            endStarField += getEndStarField(startPos.yx - endPos.yx, starSpeed) * 0.66666667;
            endStarField += getEndStarField(endPos.xy * 2.0 - startPos, starSpeed) * 0.33333333;

            // Get the depth outline for the end portal
            float edgeBrightness = exp2((blockDepth + 0.0625) * 8.0);

            // Get noise color to variate the end portal color
            vec3 noiseCol = getRng3(ivec2(startPos * 16.0) & 255) * 0.5 + 0.5;
            vec3 finalCol = (noiseCol * endStarField + edgeBrightness) * EMISSIVE_INTENSITY * vertexColor.rgb;

            sceneColOut = vec4(toLinear(finalCol), 1);

            // End portal fix
            normalDataOut = vec3(0);
            materialDataOut = vec3(0, 0, 0.5);

            return; // Return immediately, no need for lighting calculation
        }

        // Declare materials
        dataPBR material;
        getPBR(material, blockEntityId);

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        // Write to HDR scene color
        sceneColOut = complexShadingForward(material);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0.5);
    }
#endif