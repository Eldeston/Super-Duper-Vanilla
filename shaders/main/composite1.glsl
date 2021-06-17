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

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color){
	float white = 1.44;
	float luma = getLuminance(color);
	float toneMappedLuma = luma * (1.0 + luma / (white * white)) / (1.0 + luma);
	return color * (toneMappedLuma / luma);
}

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
            
            float blendFact = edgeVisibility(prevScreenPos * 0.8 + 0.1) * smoothstep(0.99999, 1.0, 1.0 - velocity);
            float decay = exp2(-ACCUMILATION_SPEED * frameTime);
            blendFact = clamp(blendFact, decay * 0.5, decay);
            
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
            float lumiCurrent = getLuminance(texture2D(gcolor, vec2(0.5), lod).rgb);
            // Top right pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(1), lod).rgb);
            // Top left pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(0, 1), lod).rgb);
            // Bottom right pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(1, 0), lod).rgb);
            // Bottom left pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(0), lod).rgb);

            // Mix previous and current buffer...
            float accumulatedLumi = mix(lumiCurrent / 5.0, texture2D(colortex6, vec2(0)).a, exp2(-1.0 * frameTime));

            // Apply exposure
            color /= max(accumulatedLumi * AUTO_EXPOSURE_MULT, MIN_EXPOSURE_DENOM);
        #else
            float accumulatedLumi = 1.0;
        #endif
        color *= EXPOSURE;
        // Tonemap and clamp
        color = saturate(whitePreservingLumaBasedReinhardToneMapping(color));

        float luminance = getLuminance(color);
        float emissive = texture2D(colortex3, texcoord).g;
        
    /* DRAWBUFFERS:026 */
        gl_FragData[0] = vec4(color, 1); //gcolor
        gl_FragData[1] = vec4(color * emissive * luminance, 1); //colortex2
        gl_FragData[2] = vec4(accumulated, max(0.001, accumulatedLumi)); //colortex6
    }
#endif