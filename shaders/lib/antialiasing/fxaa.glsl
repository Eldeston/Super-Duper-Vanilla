#define EDGE_THRESHOLD_MIN 0.03125
#define EDGE_THRESHOLD_MAX 0.125

#define ITERATIONS 12

#define SUBPIXEL_QUALITY 0.75

const float quality[12] = float[12](1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

// http://blog.simonrodriguez.fr/articles/30-07-2016_implementing_fxaa.html
vec3 textureFXAA(in vec2 screenPos, in vec2 resolution, in ivec2 screenTexelCoord){
    // Pixel size
    vec2 pixSize = 1.0 / resolution.xy;

    // Offsetted screen texel coords
    ivec2 topRightCorner = screenTexelCoord + 1;
    ivec2 bottomLeftCorner = screenTexelCoord - 1;

    // Aliased texture
    vec3 colorCenter = texelFetch(gcolor, screenTexelCoord, 0).rgb;

    // Luma at the current fragment
    float lumaCenter = getLuminance(colorCenter);

    // Luma at the four direct neighbours of the current fragment.
    float lumaTop = getLuminance(texelFetch(gcolor, ivec2(screenTexelCoord.x, topRightCorner.y), 0).rgb);
    float lumaBottom = getLuminance(texelFetch(gcolor, ivec2(screenTexelCoord.x, bottomLeftCorner.y), 0).rgb);
    float lumaLeft = getLuminance(texelFetch(gcolor, ivec2(bottomLeftCorner.x, screenTexelCoord.y), 0).rgb);
    float lumaRight = getLuminance(texelFetch(gcolor, ivec2(topRightCorner.x, screenTexelCoord.y), 0).rgb);

    // Find the maximum and minimum luma around the current fragment.
    float lumaMin = min(lumaCenter, min(min(lumaBottom, lumaTop), min(lumaLeft, lumaRight)));
    float lumaMax = max(lumaCenter, max(max(lumaBottom, lumaTop), max(lumaLeft, lumaRight)));

    // Compute the delta.
    float lumaRange = lumaMax - lumaMin;

    if(lumaRange < max(EDGE_THRESHOLD_MIN, lumaMax * EDGE_THRESHOLD_MAX)) return colorCenter;

    // Query the 4 remaining corners lumas.
    float lumaTopRight = getLuminance(texelFetch(gcolor, topRightCorner, 0).rgb);
    float lumaBottomLeft = getLuminance(texelFetch(gcolor, bottomLeftCorner, 0).rgb);
    float lumaTopLeft = getLuminance(texelFetch(gcolor, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb);
    float lumaBottomRight = getLuminance(texelFetch(gcolor, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb);

    // Combine the four edges lumas (using intermediary variables for future computations with the same values).
    float lumaBottomTop = lumaBottom + lumaTop;
    float lumaLeftRight = lumaLeft + lumaRight;

    // Same for corners
    float lumaLeftCorners = lumaBottomLeft + lumaTopLeft;
    float lumaBottomCorners = lumaBottomLeft + lumaBottomRight;
    float lumaRightCorners = lumaBottomRight + lumaTopRight;
    float lumaTopCorners = lumaTopRight + lumaTopLeft;

    // Compute an estimation of the gradient along the horizontal and vertical axis.
    float edgeHorizontal = abs(lumaLeftCorners - 2.0 * lumaLeft) + abs(lumaBottomTop - 2.0 * lumaCenter) * 2.0 + abs(lumaRightCorners - 2.0 * lumaRight);
    float edgeVertical = abs(lumaTopCorners - 2.0 * lumaTop) + abs(lumaLeftRight - 2.0 * lumaCenter) * 2.0 + abs(lumaBottomCorners - 2.0 * lumaBottom);

    // Is the local edge horizontal or vertical ?
    bool isHorizontal = (edgeHorizontal >= edgeVertical);

    // Select the two neighboring texels lumas in the opposite direction to the local edge.
    float luma1 = isHorizontal ? lumaBottom : lumaLeft;
    float luma2 = isHorizontal ? lumaTop : lumaRight;
    // Compute gradients in this direction.
    float gradient1 = luma1 - lumaCenter;
    float gradient2 = luma2 - lumaCenter;

    // Which direction is the steepest ?
    bool isSteepest = abs(gradient1) >= abs(gradient2);

    // Gradient in the corresponding direction, normalized.
    float gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));

    // Choose the step size (one pixel) according to the edge direction.
    float stepLength = isHorizontal ? pixSize.y : pixSize.x;

    // Average luma in the correct direction.
    float lumaLocalAverage = 0.0;

    if(isSteepest){
        // Switch the direction
        stepLength = -stepLength;
        lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
    }else{
        lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
    }

    // Shift UV in the correct direction by half a pixel.
    vec2 currentUv = screenPos;
    if(isHorizontal) currentUv.y += stepLength * 0.5;
    else currentUv.x += stepLength * 0.5;

    // Compute offset (for each iteration step) in the right direction.
    vec2 offset = isHorizontal ? vec2(pixSize.x, 0) : vec2(0, pixSize.y);
    // Compute UVs to explore on each side of the edge, orthogonally. The QUALITY allows us to step faster.
    vec2 uv1 = currentUv - offset;
    vec2 uv2 = currentUv + offset;

    // Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma.
    float lumaEnd1 = getLuminance(textureLod(gcolor, uv1, 0).rgb) - lumaLocalAverage;
    float lumaEnd2 = getLuminance(textureLod(gcolor, uv2, 0).rgb) - lumaLocalAverage;

    // If the luma deltas at the current extremities are larger than the local gradient, we have reached the side of the edge.
    bool reached1 = abs(lumaEnd1) >= gradientScaled;
    bool reached2 = abs(lumaEnd2) >= gradientScaled;
    bool reachedBoth = reached1 && reached2;

    // If the side is not reached, we continue to explore in this direction.
    if(!reached1) uv1 -= offset;
    if(!reached2) uv2 += offset;

    // If both sides have not been reached, continue to explore.
    if(!reachedBoth){
        for(int i = 2; i < ITERATIONS; i++){
            // If needed, read luma in 1st direction, compute delta.
            if(!reached1){
                lumaEnd1 = getLuminance(textureLod(gcolor, uv1, 0).rgb);
                lumaEnd1 = lumaEnd1 - lumaLocalAverage;
            }

            // If needed, read luma in opposite direction, compute delta.
            if(!reached2){
                lumaEnd2 = getLuminance(textureLod(gcolor, uv2, 0).rgb);
                lumaEnd2 = lumaEnd2 - lumaLocalAverage;
            }

            // If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge.
            reached1 = abs(lumaEnd1) >= gradientScaled;
            reached2 = abs(lumaEnd2) >= gradientScaled;
            reachedBoth = reached1 && reached2;

            // If the side is not reached, we continue to explore in this direction, with a variable quality.
            if(!reached1) uv1 -= offset * quality[i];
            if(!reached2) uv2 += offset * quality[i];

            // If both sides have been reached, stop the exploration.
            if(reachedBoth) break;
        }
    }

    // Compute the distances to each extremity of the edge.
    float distance1 = isHorizontal ? (screenPos.x - uv1.x) : (screenPos.y - uv1.y);
    float distance2 = isHorizontal ? (uv2.x - screenPos.x) : (uv2.y - screenPos.y);

    // Is the luma at center smaller than the local average ?
    bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;

    // If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation).
    // (in the direction of the closer side of the edge.)
    bool correctVariation = ((distance1 < distance2 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;

    // Sub-pixel shifting
    // Full weighted average of the luma over the 3x3 neighborhood.
    float lumaAverage = (2.0 * (lumaBottomTop + lumaLeftRight) + lumaLeftCorners + lumaRightCorners) * 0.0833333;
    // Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
    float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
    float subPixelOffset2 = subPixelOffset1 * subPixelOffset1 * (3.0 - 2.0 * subPixelOffset1);
    // Compute a sub-pixel offset based on this delta.
    float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * SUBPIXEL_QUALITY;

    // Compute the final UV coordinates.
    vec2 finalUv = screenPos;

    // UV offset: read in the direction of the closest side of the edge. If the luma variation is incorrect, do not offset. Pick the biggest of the two offsets.
    if(isHorizontal) finalUv.y += (correctVariation ? max(0.5 - min(distance1, distance2) / (distance1 + distance2), subPixelOffsetFinal) : subPixelOffsetFinal) * stepLength;
    else finalUv.x += (correctVariation ? max(0.5 - min(distance1, distance2) / (distance1 + distance2), subPixelOffsetFinal) : subPixelOffsetFinal) * stepLength;

    // Read the color at the new UV coordinates, and use it.
    return textureLod(gcolor, finalUv, 0).rgb;
}