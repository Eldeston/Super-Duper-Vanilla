#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/lighting/AO.glsl"
#include "/lib/lighting/shdMapping.glsl"
#include "/lib/conversion.glsl"

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

        vec3 skyRender = getSkyRender(posVector, skyCol, lightCol);

        // If the object is opaque render lighting sperately
        if(materials.alpha_m == 1.0){
            materials.albedo_t = getShdMapping(materials, posVector);
            materials.albedo_t = getFog(posVector, materials.albedo_t, skyRender);
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(materials.albedo_t, 1.0); //gcolor
    }
#endif