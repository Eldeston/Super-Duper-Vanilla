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

#include "/lib/atmospherics/complexAtmo.glsl"
#include "/lib/lighting/complexLighting.glsl"

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

        // If the object is opaque render lighting sperately
        if(materials.alpha_m == 1.0){
            vec3 dither = getRand3(texcoord, 8) * 2.0 - 1.0;
            float mask = float(posVector.screenPos.z == 1);
            
            vec3 skyRender = getSkyRender(posVector.playerPos, mask, skyCol, lightCol);

            // Apply lighting
            materials.albedo_t = materials.albedo_t * materials.ambient_m * getAmbient(materials, posVector);
            materials.albedo_t = complexLighting(materials, posVector, dither);

            // Apply atmospherics
            materials.albedo_t = getFog(posVector, materials.albedo_t, skyRender);
            materials.albedo_t += getGodRays(posVector.playerPos, dither.y) * lightCol;
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(materials.albedo_t, 1); //gcolor
    }
#endif