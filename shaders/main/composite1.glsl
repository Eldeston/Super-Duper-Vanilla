#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"
#include "/lib/lighting/shdDistort.glsl"
#include "/lib/conversion.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/AO.glsl"
#include "/lib/lighting/GGX.glsl"
#include "/lib/lighting/shdMapping.glsl"
#include "/lib/lighting/complexLighting.glsl"

#include "/lib/raymarching/volLighting.glsl"
#include "/lib/raymarching/SSR.glsl"

#include "/lib/varAssembler.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, texcoord);

	    // Declare and get materials
	    matPBR materials;
	    getMaterial(materials, texcoord);

        vec3 reflectedPlayerPos = reflect(posVector.playerPos, materials.normal_m);
        float mask = float(posVector.screenPos.z >= 1.0);

        vec3 dither = toScreenSpacePos(getRandVec(posVector.screenPos.xy, 8).xy);
        vec3 nPlayerPos = normalize(-posVector.playerPos);

        vec3 skyRender = getSkyRender(posVector.playerPos, mask, skyCol, lightCol);
        vec3 shdCol = getShdMapping(materials, posVector);
        vec3 specCol = getSpecGGX(materials, posVector);
    
        vec3 reflectedScreenPos = getScreenPosReflections(posVector.screenPos, mat3(gbufferModelView) * materials.normal_m, dither * squared(materials.roughness_m * materials.roughness_m));
        vec3 reflectedSkyRender = getSkyRender(reflectedPlayerPos, 10, skyCol, lightCol) * materials.light_m.y;
        
        float fresnel = getFresnel(materials.normal_m, nPlayerPos, materials.metallic_m);
        vec3 reflectBuffer = vec3(0.0);

        // If the object is transparent render lighting sperately
        if(materials.alpha_m != 1.0){
            materials.albedo_t = materials.albedo_t * materials.ambient_m * getAmbient(materials, posVector);
            materials.albedo_t = complexLighting(materials, shdCol, specCol);

            // Apply reflections
            vec3 reflectCol = reflectedSkyRender * (1.0 - reflectedScreenPos.z) + texture2D(colortex6, reflectedScreenPos.xy).rgb * reflectedScreenPos.z;
            materials.albedo_t += saturate(reflectCol) * materials.metallic_m * fresnel; // Will change this later next patch

            // Assign to reflect buffer before applying atmospherics
            reflectBuffer = materials.albedo_t;

            // Apply atmospherics
            materials.albedo_t = getFog(posVector, materials.albedo_t, skyRender);
            materials.albedo_t += getGodRays(posVector.playerPos, dither.y) * lightCol;
        }

    /* DRAWBUFFERS:06 */
        gl_FragData[0] = vec4(materials.albedo_t, 1); //gcolor
        gl_FragData[1] = vec4(materials.albedo_t, 1); //colortex6
    }
#endif