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

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef TEMPORAL_ACCUMULATION
            vec2 prevScreenPos = toPrevScreenPos(texcoord);
            float prevMotion = max2(toPrevScreenPos(vec2(1)));
            float velocity = abs(1.0 - prevMotion);
            
            float blendFact = edgeVisibility(prevScreenPos * 0.8 + 0.1);
            blendFact *= smoothstep(0.99999, 1.0, 1.0 - velocity);
            blendFact = clamp(blendFact, 0.1, exp2(-ACCUMILATION_SPEED * frameTime));
            
            vec3 prevCol = texture2D(colortex6, texcoord).rgb;
            vec3 accumulated = mix(color, prevCol, blendFact);
            color = accumulated;
        #else
            vec3 accumulated = vec3(0);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get lod
            float lod = int(exp2(min(viewWidth, viewHeight))) - 1.0;
            
            // Get current average scene luminance...
            // Center pixel
            float lumiCurrent = maxC(texture2D(gcolor, vec2(0.5), lod).rgb);
            // Top right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1), lod).rgb);
            // Top left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0, 1), lod).rgb);
            // Bottom right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1, 0), lod).rgb);
            // Bottom left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0), lod).rgb);

            // Previous luminance
            float lumiPrev = texture2D(colortex6, vec2(0)).a;
            // Mix previous and current buffer...
            float finalLumi = mix(lumiCurrent / 5.0, lumiPrev, exp2(-1.0 * frameTime));

            // Apply exposure
            color /= max(finalLumi * 2.0, 0.6);
        #else
            float finalLumi = 1.0;
        #endif
        color *= EXPOSURE;
        // Tonemap and clamp
        color = saturate(color / (color * 0.2 + 1.0));

        float skyMask = float(texture2D(depthtex0, texcoord).r != 1);
        float luminance = getLuminance(color);
        float emissive = texture2D(colortex3, texcoord).g;
        
    /* DRAWBUFFERS:067 */
        gl_FragData[0] = vec4(color, 1); //gcolor
        gl_FragData[1] = vec4(accumulated, finalLumi); //colortex6
        gl_FragData[2] = vec4(color * emissive * skyMask * luminance, 1); //colortex7
    }
#endif