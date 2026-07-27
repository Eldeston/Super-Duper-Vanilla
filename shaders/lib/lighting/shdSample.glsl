// Shadow opaque
uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
    // Shadow color
    uniform sampler2D shadowcolor0;

    // Shadow w/o translucents
    uniform sampler2DShadow shadowtex1;
#endif

vec3 getShdCol(in vec3 shdPos){
    #ifdef SHADOW_COLOR
        // Sample shadows
        float shd0 = textureLod(shadowtex0, shdPos, 0);
        // If not in shadow, return "white"
        if(shd0 == 1) return vec3(1);
        // Sample opaque only shadows
        float shd1 = textureLod(shadowtex1, shdPos, 0);
        // If in shadow, return "black"
        if(shd1 == 0) return vec3(0);
        // Otherwise, calculate the full shadow color
        return texelFetch(shadowcolor0, ivec2(shdPos.xy * shadowMapResolution), 0).rgb * (1.0 - shd0) * shd1 + shd0;
    #else
        // Sample shadows and return directly
        return vec3(textureLod(shadowtex0, shdPos, 0));
    #endif
}

vec3 getShdCol(in vec3 shdPos, in vec2 randVec){
    #if ANTI_ALIASING >= 2
        return getShdCol(vec3(shdPos.xy + randVec, shdPos.z));
    #else
        return (getShdCol(vec3(shdPos.xy + randVec, shdPos.z)) + getShdCol(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
    #endif
}