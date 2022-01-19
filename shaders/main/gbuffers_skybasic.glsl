#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
    }
#endif

#ifdef FRAGMENT
    // Force disable story mode clouds
    #ifndef FORCE_DISABLE_CLOUDS
        #define FORCE_DISABLE_CLOUDS
    #endif

    uniform sampler2D colortex7;

    // View matrix uniforms
    uniform mat4 gbufferModelViewInverse;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    // Get world time
    uniform float day;
    uniform float dawnDusk;
    uniform float twilight;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    uniform vec3 fogColor;

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/sky.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;

        // Get sky color
        vec3 skyRender = getSkyRender(posVector.eyePlayerPos, true, true);

    /* DRAWBUFFERS:7 */
        gl_FragData[0] = vec4(skyRender, texture2D(colortex7, posVector.screenPos.xy).a); //colortex7
    }
#endif