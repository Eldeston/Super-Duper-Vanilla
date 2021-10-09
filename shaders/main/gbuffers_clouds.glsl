#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texCoord;

INOUT vec3 norm;

#ifdef VERTEX
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #if defined DOUBLE_VANILLA_CLOUDS
        uniform int instanceId;

        const int countInstances = 2;
    #endif
    
    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        vec2 coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #ifdef DOUBLE_VANILLA_CLOUDS
            texCoord = instanceId == 1 ? coord : -coord;
            if(instanceId > 0) vertexPos.y += SECOND_CLOUD_HEIGHT * instanceId;
        #else
            texCoord = coord;
        #endif

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;
    
    #include "/lib/globalVars/matUniforms.glsl"
    #include "/lib/globalVars/posUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    #include "/lib/assemblers/posAssembler.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 dither = getRand3(posVector.screenPos.xy, 8);
	    getPosVectors(posVector);

	    // Declare materials
	    matPBR material;

        float albedoAlpha = texture2D(texture, texCoord).a;
        // Assign normals
        material.normal = norm;

        #ifdef CLOUD_FADE
            float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
            float albedoAlpha2 = texture2D(texture, 0.5 - texCoord).a;
            albedoAlpha = mix(albedoAlpha, albedoAlpha2, fade * (1.0 - rainStrength) + albedoAlpha2 * rainStrength);
        #endif

        #if WHITE_MODE == 2
            material.albedo = vec4(0, 0, 0, albedoAlpha);
        #else
            material.albedo = vec4(1, 1, 1, albedoAlpha);
        #endif

        material.metallic = 0.04;
        material.ss = 0.0;
        material.emissive = 0.0;
        material.smoothness = 0.0;

        // Apply vanilla AO
        material.ambient = 1.0;
        material.light = vec2(0, 1);

        vec4 sceneCol = vec4(0);
        if(material.albedo.a > 0.00001) sceneCol = complexShadingGbuffers(material, posVector, dither);
        else discard;

    /* DRAWBUFFERS:0124 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(0, 1, 0, 1); //colortex4
    }
#endif