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

        vec3 dither = toScreenSpacePos(getRandVec(posVector.screenPos.xy, 8).xy);
        vec3 nPlayerPos = normalize(-posVector.playerPos);
        
        vec3 skyRender = getSkyRender(posVector, skyCol, lightCol);
        vec3 shdRender = getShdMapping(materials, posVector);
        vec3 reflectedScreenPos = getScreenPosReflections(posVector.screenPos, mat3(gbufferModelView) * materials.normal_m, dither * 0.0);

        float fresnel = getFresnel(materials.normal_m, nPlayerPos, materials.metallic_m);
        vec3 reflectBuffer = vec3(0.0);

        // If the object is opaque render lighting sperately
        if(materials.alpha_m == 1.0){
            materials.albedo_t = materials.albedo_t * materials.ambient_m * getAmbient(materials, posVector);
            materials.albedo_t *= shdRender;

            // Apply reflections
            vec3 reflectCol = texture2D(colortex6, reflectedScreenPos.xy).rgb * reflectedScreenPos.z * materials.metallic_m;
            materials.albedo_t += saturate(reflectCol); // Will change this later next patch

            // Assign to reflect buffer before applying atmospherics
            reflectBuffer = materials.albedo_t;

            // Apply atmospherics
            materials.albedo_t = getFog(posVector, materials.albedo_t, skyRender);
            materials.albedo_t += getGodRays(posVector.playerPos, gl_FragCoord.xy) * lightCol * 0.32;
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(materials.albedo_t, 1.0); //gcolor
        gl_FragData[1] = vec4(materials.albedo_t, 1.0); //colortex6
    }
#endif