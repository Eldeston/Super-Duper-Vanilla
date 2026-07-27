// Shadow opaque
uniform sampler2D shadowtex0;

#ifdef SHADOW_COLOR
    // Shadow color
    uniform sampler2D shadowcolor0;

    // Shadow w/o translucents
    uniform sampler2D shadowtex1;
#endif

vec3 getShdCol(in vec3 shdPos){
    ivec2 texelShdPos = ivec2(shdPos.xy * shadowMapResolution);

    #ifdef SHADOW_COLOR
        // Test shadows, if not in shadow, return "white"
        if(shdPos.z < texelFetch(shadowtex0, texelShdPos, 0).x) return vec3(1);
        // Test opaque only shadows, if in shadow, return "black"
        if(shdPos.z > texelFetch(shadowtex1, texelShdPos, 0).x) return vec3(0);
        // Otherwise, calculate the full shadow color
        return texelFetch(shadowcolor0, texelShdPos, 0).rgb;
    #else
        // Sample shadows and return directly
        return vec3(shdPos.z < texelFetch(shadowtex0, texelShdPos, 0).x);
    #endif
}

vec3 getShdCol(in vec3 shdPos, in vec2 randVec){
    #if ANTI_ALIASING >= 2
        return getShdCol(vec3(shdPos.xy + randVec, shdPos.z));
    #else
        return (getShdCol(vec3(shdPos.xy + randVec, shdPos.z)) + getShdCol(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
    #endif
}