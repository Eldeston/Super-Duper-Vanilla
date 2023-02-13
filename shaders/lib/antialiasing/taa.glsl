// https://sugulee.wordpress.com/2021/06/21/temporal-anti-aliasingtaa-tutorial/
vec3 textureTAA(in ivec2 screenTexelCoord){
    // Current color
    vec3 currColor = texelFetch(gcolor, screenTexelCoord, 0).rgb;
    // Previous color
    vec3 prevColor = textureLod(colortex5, toPrevScreenPos(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x), 0).rgb;

    // Apply clamping on the history color.
    vec3 nearCol0 = texelFetch(gcolor, ivec2(screenTexelCoord.x - 1, screenTexelCoord.y), 0).rgb;
    vec3 nearCol1 = texelFetch(gcolor, ivec2(screenTexelCoord.x, screenTexelCoord.y - 1), 0).rgb;
    vec3 nearCol2 = texelFetch(gcolor, ivec2(screenTexelCoord.x + 1, screenTexelCoord.y), 0).rgb;
    vec3 nearCol3 = texelFetch(gcolor, ivec2(screenTexelCoord.x, screenTexelCoord.y + 1), 0).rgb;
    
    vec3 boxMin = min(currColor, min(nearCol0, min(nearCol1, min(nearCol2, nearCol3))));
    vec3 boxMax = max(currColor, max(nearCol0, max(nearCol1, max(nearCol2, nearCol3))));;
    
    // Required to add the "sum color" of the remaining VL
    prevColor = clamp(prevColor, boxMin, boxMax);

    // Return temporal color
    return currColor * 0.1 + prevColor * 0.9;
}