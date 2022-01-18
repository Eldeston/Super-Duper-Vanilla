// https://sugulee.wordpress.com/2021/06/21/temporal-anti-aliasingtaa-tutorial/

vec3 textureTAA(sampler2D aliased, sampler2D temporal, vec2 screenPos, vec2 resolution){
    vec2 prevPos = toPrevScreenPos(screenPos);

    vec3 currColor = texture2D(aliased, screenPos).rgb;
    vec3 prevColor = texture2D(temporal, prevPos).rgb;

    vec2 offSet0 = vec2(1.0 / resolution.x, 0);
    vec2 offSet1 = vec2(0, 1.0 / resolution.y);

    // Apply clamping on the history color.
    vec3 nearCol0 = texture2D(aliased, screenPos - offSet0).rgb;
    vec3 nearCol1 = texture2D(aliased, screenPos - offSet1).rgb;
    vec3 nearCol2 = texture2D(aliased, screenPos + offSet0).rgb;
    vec3 nearCol3 = texture2D(aliased, screenPos + offSet1).rgb;
    
    vec3 boxMin = min(currColor, min(nearCol0, min(nearCol1, min(nearCol2, nearCol3))));
    vec3 boxMax = max(currColor, max(nearCol0, max(nearCol1, max(nearCol2, nearCol3))));;
    
    prevColor = clamp(prevColor, boxMin, boxMax);

    return mix(currColor, prevColor, 0.9);
}