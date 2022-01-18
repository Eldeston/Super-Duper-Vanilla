#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

uniform int isEyeInWater;

uniform float nightVision;
uniform float rainStrength;

uniform ivec2 eyeBrightnessSmooth;

// Get frame time
uniform float frameTimeCounter;

// Get world time
uniform float day;
uniform float dawnDusk;
uniform float twilight;

INOUT float blockId;

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

#if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
    INOUT vec2 minTexCoord;
    INOUT vec2 maxTexCoord;
#endif

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    #include "/lib/vertex/vertexWave.glsl"

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    attribute vec2 mcidTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        blockId = mc_Entity.x;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));
	    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, binormal, normal);

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mcidTexCoord, mc_Entity.x, lmCoord.y);
        #endif

        #if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
            vec2 texSize = abs(texCoord - mcidTexCoord.xy);
            minTexCoord = mcidTexCoord.xy - texSize;
            maxTexCoord = mcidTexCoord.xy + texSize;
            texCoord = step(mcidTexCoord.xy, texCoord);
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    // View matrix uniforms
    uniform mat4 gbufferModelViewInverse;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;

    /* Position uniforms */
    uniform vec3 cameraPosition;

    uniform vec3 shadowLightPosition;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;
    
    uniform vec3 fogColor;

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/surface/lava.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;
        posVector.worldPos = posVector.feetPlayerPos + cameraPosition;

        #ifdef END
			posVector.lightPos = shadowLightPosition;
		#else
			posVector.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz;
		#endif
	
		#ifdef SHD_ENABLE
			posVector.shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
		#endif

	    // Declare materials
	    matPBR material;
        int rBlockId = int(blockId + 0.5);
        getPBR(material, posVector, TBN, glcolor.rgb, texCoord, rBlockId);

        vec4 sceneCol = vec4(0);

        if(material.albedo.a > 0.00001){
            if(rBlockId == 10017){
                #ifdef LAVA_NOISE
                    vec2 lavaUv = posVector.worldPos.xz * (1.0 - TBN[2].y) + posVector.worldPos.xz * TBN[2].y;
                    float lavaWaves = max(getLuminance(material.albedo.rgb), getCellNoise2(floor(lavaUv * 16.0) / (LAVA_TILE_SIZE * 16.0)));
                    material.albedo.rgb = floor(material.albedo.rgb * (LAVA_BRIGHTNESS * smootherstep(lavaWaves) * 32.0)) / 32.0;
                #else
                    material.albedo.rgb = material.albedo.rgb * LAVA_BRIGHTNESS;
                #endif
            }

            material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

            // Apply vanilla AO
            material.ambient *= glcolor.a;
            material.light = lmCoord;

            #ifdef ENVIRO_MAT
                enviroPBR(material, posVector.worldPos, TBN[2]);
            #endif

            #if ANTI_ALIASING == 2
                sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(posVector.screenPos.xy, 8), frameTimeCounter));
            #else
                sceneCol = complexShadingGbuffers(material, posVector, getRand1(posVector.screenPos.xy, 8));
            #endif
        } else discard;

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.emissive, material.smoothness, 1); //colortex3
    }
#endif