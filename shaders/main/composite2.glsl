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
            // Get current average scene brightenss...
            // Middle pixel
            vec3 colCurrent = texture2D(gcolor, vec2(0.5), lod).rgb;
            // Top right pixel
            colCurrent += texture2D(gcolor, vec2(1), lod).rgb;
            // Top left pixel
            colCurrent += texture2D(gcolor, vec2(0, 1), lod).rgb;
            // Bottom right pixel
            colCurrent += texture2D(gcolor, vec2(1, 0), lod).rgb;
            // Bottom left pixel
            colCurrent += texture2D(gcolor, vec2(0), lod).rgb;
            // Previous color
            vec3 colPrev = texture2D(colortex6, vec2(0.5), lod).rgb;
            // Mix previous and current buffer...
            vec3 finalCol = mix(colCurrent / 5.0, colPrev, exp2(-1.0 * frameTime));

            // Calculate luminance
            float lumi = maxC(colPrev);
            // Apply exposure
            color /= max(lumi * 2.0, 0.5);
        #endif
        color *= EXPOSURE;
        // Clamp
        color = saturate(color);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef AUTO_EXPOSURE
        /* DRAWBUFFERS:06 */
            gl_FragData[1] = vec4(finalCol, 1); //colortex6
        #endif
    }
#endif