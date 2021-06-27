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

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

#ifdef VERTEX
    attribute vec2 mc_midTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	    norm = normalize(gl_NormalMatrix * gl_Normal);
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 albedo = vec4(glcolor.rgb, 1);
        albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 dither = getRand3(screenPos.xy, 8);

        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, screenPos);

	    // Declare materials
	    matPBR materials;

        #if defined WHITE_MODE && !defined WHITE_MODE_F
            albedo.rgb = vec3(1);
        #endif

        materials.metallic_m = 0.0;
        materials.ss_m = 1.0;
        materials.emissive_m = 0.0;
        materials.roughness_m = 1.0;

        // Apply vanilla AO
        materials.ambient_m = glcolor.a;

        // Transfor final normals to player space
        materials.normal_m = mat3(gbufferModelViewInverse) * norm;
        materials.albedo_t = albedo;
        materials.light_m = lmCoord;

        vec4 sceneCol = complexShadingGbuffers(materials, posVector, dither);

    /* DRAWBUFFERS:01234 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(materials.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = materials.albedo_t; //colortex2
        gl_FragData[3] = vec4(materials.metallic_m, materials.emissive_m, materials.roughness_m, 1); //colortex3
        gl_FragData[4] = vec4(materials.ambient_m, 0, 0, 1); //colortex4
    }
#endif