#define EDGE_THRESHOLD_MIN 0.03125
#define EDGE_THRESHOLD_MAX 0.125

#define ITERATIONS 12

#define SUBPIXEL_QUALITY 0.75

const float quality[12] = float[12](1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

// http://blog.simonrodriguez.fr/articles/30-07-2016_implementing_fxaa.html
vec3 textureFXAA(in ivec2 screenTexelCoord){
    // Offsetted screen texel coords
    ivec2 topRightCorner = screenTexelCoord + 1;
    ivec2 bottomLeftCorner = screenTexelCoord - 1;

    // Aliased texture
    vec3 colorCenter = texelFetch(colortex3, screenTexelCoord, 0).rgb;

    // Luma at the current fragment
    float lumaCenter = sumOf(colorCenter);

    // Luma at the four direct neighbours of the current fragment.
    float lumaTop = sumOf(texelFetch(colortex3, ivec2(screenTexelCoord.x, topRightCorner.y), 0).rgb);
    float lumaBottom = sumOf(texelFetch(colortex3, ivec2(screenTexelCoord.x, bottomLeftCorner.y), 0).rgb);
    float lumaLeft = sumOf(texelFetch(colortex3, ivec2(bottomLeftCorner.x, screenTexelCoord.y), 0).rgb);
    float lumaRight = sumOf(texelFetch(colortex3, ivec2(topRightCorner.x, screenTexelCoord.y), 0).rgb);

    // Find the maximum and minimum luma around the current fragment.
    float lumaMin = min(lumaCenter, min(min(lumaBottom, lumaTop), min(lumaLeft, lumaRight)));
    float lumaMax = max(lumaCenter, max(max(lumaBottom, lumaTop), max(lumaLeft, lumaRight)));

    // Compute the delta.
    float lumaRange = lumaMax - lumaMin;

    const float edgeThresholdMin = EDGE_THRESHOLD_MIN * 3.0;
    if(lumaRange < max(edgeThresholdMin, lumaMax * EDGE_THRESHOLD_MAX)) return colorCenter;

    // Query the 4 remaining corners lumas.
    float lumaTopRight = sumOf(texelFetch(colortex3, topRightCorner, 0).rgb);
    float lumaBottomLeft = sumOf(texelFetch(colortex3, bottomLeftCorner, 0).rgb);
    float lumaTopLeft = sumOf(texelFetch(colortex3, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb);
    float lumaBottomRight = sumOf(texelFetch(colortex3, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb);

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
    bool isHorizontal = edgeHorizontal >= edgeVertical;

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
    float stepLength = isHorizontal ? pixelWidth : pixelHeight;

    // Average luma in the correct direction.
    float lumaLocalAverage = lumaCenter;

    if(isSteepest){
        // Switch the direction
        stepLength = -stepLength;
        lumaLocalAverage += luma1;
    }
    else{
        lumaLocalAverage += luma2;
    }

    lumaLocalAverage *= 0.5;

    // Shift UV in the correct direction by half a pixel.
    float halfStepLength = stepLength * 0.5;
    vec2 currentUv = texCoord;
    if(isHorizontal) currentUv.y += halfStepLength;
    else currentUv.x += halfStepLength;

    // Compute offset (for each iteration step) in the right direction.
    vec2 offset = isHorizontal ? vec2(pixelHeight, 0) : vec2(0, pixelWidth);
    // Compute UVs to explore on each side of the edge, orthogonally. The QUALITY allows us to step faster.
    vec2 uv1 = currentUv - offset;
    vec2 uv2 = currentUv + offset;

    // Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma.
    float lumaEnd1 = sumOf(textureLod(colortex3, uv1, 0).rgb) - lumaLocalAverage;
    float lumaEnd2 = sumOf(textureLod(colortex3, uv2, 0).rgb) - lumaLocalAverage;

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
            if(!reached1) lumaEnd1 = sumOf(textureLod(colortex3, uv1, 0).rgb) - lumaLocalAverage;

            // If needed, read luma in opposite direction, compute delta.
            if(!reached2) lumaEnd2 = sumOf(textureLod(colortex3, uv2, 0).rgb) - lumaLocalAverage;

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
    float distance1 = isHorizontal ? (texCoord.x - uv1.x) : (texCoord.y - uv1.y);
    float distance2 = isHorizontal ? (uv2.x - texCoord.x) : (uv2.y - texCoord.y);

    // In which direction is the extremity of the edge closer ?
    bool isDirection1 = distance1 < distance2;
    float distanceFinal = min(distance1, distance2);

    // Length of the edge.
    float edgeThickness = distance1 + distance2;

    // UV offset: read in the direction of the closest side of the edge.
    float pixelOffset = 0.5 - distanceFinal / edgeThickness;

    // Is the luma at center smaller than the local average ?
    bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;

    // If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation).
    // (in the direction of the closer side of the edge.)
    bool correctVariation = (isDirection1 ? lumaEnd1 : lumaEnd2) < 0 != isLumaCenterSmaller;

    // Sub-pixel shifting
    // Full weighted average of the luma over the 3x3 neighborhood.
    float lumaAverage = (2.0 * (lumaBottomTop + lumaLeftRight) + lumaLeftCorners + lumaRightCorners) * 0.08333333;
    // Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
    float subPixelOffset = smoothen(saturate(abs(lumaAverage - lumaCenter) / lumaRange));
    // Compute a sub-pixel offset based on this delta.
    float subPixelOffsetFinal = squared(subPixelOffset) * SUBPIXEL_QUALITY;

    // If the luma variation is incorrect, do not offset.
    // Pick the biggest of the two offsets.
    float finalOffset = correctVariation ? max(pixelOffset, subPixelOffsetFinal) : subPixelOffsetFinal;
    // Scale final offset to pixel length
    finalOffset *= stepLength;

    // Compute the final UV coordinates.
    vec2 finalUv = texCoord;

    if(isHorizontal) finalUv.y += finalOffset;
    else finalUv.x += finalOffset;

    // Read the color at the new UV coordinates, and use it.
    return textureLod(colortex3, finalUv, 0).rgb;
}