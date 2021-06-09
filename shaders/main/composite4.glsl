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

INOUT float pixSize;

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
        pixSize = 0.5 / max(viewWidth, viewHeight);

        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        gl_Position.xy += jitterPos(gl_Position);
    }
#endif

#ifdef FRAGMENT
    void main(){
        #ifdef TAA
            vec3 currCol = texture2D(gcolor, texcoord).rgb;
            vec3 minCol = currCol;
            vec3 maxCol = currCol;

            vec2 prevPos = toPrevScreenPos(texcoord);

            for(int y = -1; y <= 1; y++){
                for(int x = -1; x <= 1; x++){
                    vec3 color = texture2D(gcolor, texcoord + vec2(x, y) * pixSize).rgb;
                    minCol = min(minCol, color);
                    maxCol = max(maxCol, color);
                }
            }

            vec3 prevCol = texture2D(colortex8, prevPos).rgb;
            prevCol = max(maxCol, min(minCol, prevCol));

            vec3 finalCol = mix(currCol, prevCol, exp2(0.1 * -frameTime));

        /* DRAWBUFFERS:08 */
            gl_FragData[0] = vec4(finalCol, 1); //gcolor
            gl_FragData[1] = vec4(prevCol, 1); //colortex8
        #endif
    }
#endif