#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main() {
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef AUTO_EXPOSURE
            // Get lod
            float lod = int(exp2(min(viewWidth, viewHeight))) - 1.0;
            // Get average scene brightenss...
            vec3 colCurrent = texture2D(gcolor, vec2(0.5), lod).rgb;
            vec3 colPrev = texture2D(colortex6, vec2(0.5), lod).rgb;
            // Mix previous and current buffer...
            vec3 finalCol = mix(colCurrent, colPrev, exp2(-1.0 * frameTime));

            // Calculate luminance
            float lumi = maxC(colPrev);
            // Apply exposure
            color /= clamp(lumi * 2.0, 0.5, 2.5);
        #endif
        // Clamp
        color = saturate(color * EXPOSURE);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef AUTO_EXPOSURE
        /* DRAWBUFFERS:06 */
            gl_FragData[1] = vec4(finalCol, 1); //colortex6
        #endif
    }
#endif