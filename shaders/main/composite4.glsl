#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/matUniforms.glsl"
#include "/lib/globalVars/posUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/utility/spaceConvert.glsl"
#include "/lib/utility/texFunctions.glsl"

#include "/lib/post/outline.glsl"

INOUT vec2 texcoord;

vec2 TAAOffSet[8] = vec2[8](
	vec2( 0.0625, -0.1875),
	vec2(-0.0625,  0.1875),
	vec2( 0.3125,  0.0625),
	vec2(-0.1875, -0.3125),
	vec2(-0.3125,  0.3125),
	vec2(-0.4375, -0.0625),
	vec2( 0.1875,  0.4375),
	vec2( 0.4375, -0.4375)
);
						   
vec2 jitterPos(vec4 pos) {
	return TAAOffSet[int(modFract(frameCounter, 8))] * (pos.w / vec2(viewWidth, viewHeight));
}

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        #ifdef TAA
            ivec2 newCoords = ivec2(viewWidth, viewHeight);
            newCoords.x = int(newCoords.x * texcoord.x);
            newCoords.y = int(newCoords.y * texcoord.y);
            
            vec3 sample0 = texelFetch(gcolor, texcoord, 0).rgb;
            vec3 sample1 = texelFetch(gcolor, texcoord, 1).rgb;
            vec3 sample2 = texelFetch(gcolor, texcoord, 2).rgb;
            vec3 sample3 = texelFetch(gcolor, texcoord, 3).rgb;

            float edge = getOutline(depthtex0, screenCoord, OUTLINE_PIX_SIZE);
            vec3 currCol = mix(sample0, (sample0 + sample1 + sample2 + sample3) / 4.0, edge);

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(currCol, 1); //gcolor
        #endif
    }
#endif