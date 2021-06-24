#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/matUniforms.glsl"
#include "/lib/globalVars/posUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"
#include "/lib/globalVars/universalVars.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/utility/spaceConvert.glsl"
#include "/lib/utility/texFunctions.glsl"

#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/shdMapping.glsl"
#include "/lib/lighting/GGX.glsl"

#include "/lib/vertex/vertexWave.glsl"

#include "/lib/lighting/complexShadingForward.glsl"

#include "/lib/assemblers/posAssembler.glsl"

#if defined DOUBLE_VANILLA_CLOUDS && defined VERTEX
    uniform int instanceId;

    const int countInstances = 2;
#endif

INOUT vec2 texCoord;

INOUT vec3 norm;

#ifdef VERTEX
    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        vec2 coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #ifdef DOUBLE_VANILLA_CLOUDS
            texCoord = instanceId == 1 ? coord : -coord;
            if(instanceId > 0) vertexPos.y += 64.0 * instanceId;
        #else
            texCoord = coord;
        #endif

	    norm = normalize(gl_NormalMatrix * gl_Normal);
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 dither = getRand3(screenPos.xy, 8);

        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, screenPos);

	    // Declare materials
	    matPBR materials;

        materials.metallic_m = 0.0;
        materials.ss_m = 0.7;
        materials.emissive_m = 0.0;
        materials.roughness_m = 1.0;

        // Apply vanilla AO
        materials.ambient_m = 1.0;

        // Transfor final normals to player space
        materials.normal_m = mat3(gbufferModelViewInverse) * norm;
        materials.albedo_t = albedo;
        materials.light_m = vec2(0, 1);

        vec4 sceneCol = complexShadingGbuffers(materials, posVector, dither);

    /* DRAWBUFFERS:012347 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(materials.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(materials.light_m, materials.ss_m, 1); //colortex2
        gl_FragData[3] = vec4(materials.metallic_m, materials.emissive_m, materials.roughness_m, 1); //colortex3
        gl_FragData[4] = vec4(materials.ambient_m, 1, 0, 1); //colortex4
        gl_FragData[5] = materials.albedo_t; //colortex7
    }
#endif