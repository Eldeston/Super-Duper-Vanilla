const uint volumetricCloudSteps = uint(VOLUMETRIC_CLOUD_STEPS);

const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 0.5;
const float volumetricCloudHeight = 195.0 + volumetricCenterDepth;

// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float dither, in bool isSky){
    // Quick rejection: if the ray points away from the cloud slab, skip immediately.
    // Camera is inside the slab when -VOLUMETRIC_CLOUD_DEPTH <= cameraPos.y <= 0.
    // If looking up (y>0) from above slab top (cameraPos.y > 0), or looking down (y<0)
    // from below slab bottom (cameraPos.y < -DEPTH), no ray-cloud intersection is possible.
    // Performance contribution by Kawwabi.
    float cloudDepthNeg = -VOLUMETRIC_CLOUD_DEPTH;
    if((nFeetPlayerPos.y > 0.0 && cameraPos.y > 0.0) || (nFeetPlayerPos.y < 0.0 && cameraPos.y < cloudDepthNeg)) return vec2(0);

    // Minimum cloud distance, if terrain, caps distance to the minimum cloud distance
    float cloudFar = isSky ? volumetricCloudFar : min(volumetricCloudFar, feetPlayerDist);
    float invCloudFarSqrd = 1.0 / squared(volumetricCloudFar);

    // Sets the bounding box vertically
    float lowerBoundDist = (cloudDepthNeg - cameraPos.y) / nFeetPlayerPos.y;
    float higherBoundDist = -cameraPos.y / nFeetPlayerPos.y;

    // Finds the nearest and furthest plane
    float nearestPlane = max(min(lowerBoundDist, higherBoundDist), 0.0);
    float furthestPlane = min(cloudFar, max(lowerBoundDist, higherBoundDist));

    // If the clouds are outside the bounding box, return nothing
    if(furthestPlane < 0) return vec2(0);

    // Get distance inside the cloud
    float distInsideCloud = furthestPlane - nearestPlane;

    // Calculate cloud steps that dynamically increase with distance
    uint dynamicVolumetricCloudSteps = min(uint(distInsideCloud), volumetricCloudSteps);
    float volumetricCloudStepsInverse = 1.0 / dynamicVolumetricCloudSteps;

    // Step size along the ray (in normalized-direction units)
    float stepSize = distInsideCloud * volumetricCloudStepsInverse;

    // Multiply by volumetricCloudStepsInverse to get the step vector
    vec3 endPos = nFeetPlayerPos * stepSize;

    // Camera position as its start position, and initial t-parameter along the ray
    vec3 startPos = cameraPos + nFeetPlayerPos * nearestPlane + endPos * dither;
    float t = nearestPlane + dither * stepSize;

    // To store the cloud data for 2 cloud layers
    vec2 clouds = vec2(0);

    // Cached texel coordinate to avoid redundant texture fetches on sub-texel steps
    // Performance contribution by Kawwabi.
    ivec2 lastTexelCoord = ivec2(-1);
    vec2 cloudData = vec2(0);

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < dynamicVolumetricCloudSteps; i++){
        // Get cloud fog from the ray parameter t (avoids re-computing lengthSquared each step)
        // Since nFeetPlayerPos is normalized: lengthSquared(nFeetPlayerPos * t) == t * t
        float cloudFog = 1.0 - t * t * invCloudFarSqrd;

        // Get cloud texture, skipping if we're still on the same texel
        ivec2 texelCoord = ivec2(startPos.xz * 0.0625) & 255;
        if(texelCoord != lastTexelCoord){
            cloudData = texelFetch(colortex0, texelCoord, 0).xy;
            lastTexelCoord = texelCoord;
        }

        // Apply cloud gradient
        // Check if ray is inside a cloud
        if(cloudData.x > 0.5) clouds.x = max(clouds.x, -startPos.y * cloudFog);
        if(cloudData.y > 0.5) clouds.y = max(clouds.y, -startPos.y * cloudFog);

        // Continue tracing
        startPos += endPos;
        t += stepSize;
    }

    // Otherwise, return nothing
    return clouds;
}
