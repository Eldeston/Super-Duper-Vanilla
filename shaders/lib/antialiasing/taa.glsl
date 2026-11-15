// https://sugulee.wordpress.com/2021/06/21/temporal-anti-aliasingtaa-tutorial/
vec3 textureTAA(in ivec2 screenTexelCoord){
    // Current color
    vec3 currColor = texelFetch(colortex4, screenTexelCoord, 0).rgb;
    
    // Previous coord
    vec2 prevTexCoord = getPrevScreenCoord(texCoord, getDepth(depthtex0, screenTexelCoord, 0));
    if(prevTexCoord.x < 0 || prevTexCoord.y < 0 || prevTexCoord.x > 1 || prevTexCoord.y > 1) return currColor;

    // Previous color
    vec3 prevColor = texelFetch(colortex5, ivec2(prevTexCoord.x * viewWidth, prevTexCoord.y * viewHeight), 0).rgb;

    // Apply clamping on the history color.
    vec3 nearCol0 = texelFetch(colortex4, ivec2(screenTexelCoord.x - 1, screenTexelCoord.y), 0).rgb;
    vec3 nearCol1 = texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y - 1), 0).rgb;
    vec3 nearCol2 = texelFetch(colortex4, ivec2(screenTexelCoord.x + 1, screenTexelCoord.y), 0).rgb;
    vec3 nearCol3 = texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y + 1), 0).rgb;
    
    vec3 boxMin = min(currColor, min(nearCol0, min(nearCol1, min(nearCol2, nearCol3))));
    vec3 boxMax = max(currColor, max(nearCol0, max(nearCol1, max(nearCol2, nearCol3))));

    // Required to add the "sum color" of the remaining VL
    prevColor = clamp(prevColor, boxMin, boxMax);

    // Return temporal color
    return currColor * 0.1 + prevColor * 0.9;
}