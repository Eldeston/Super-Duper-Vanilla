const uint volumetricCloudSteps = uint(VOLUMETRIC_CLOUD_STEPS);
const float volumetricCloudStepsInv = 1.0 / volumetricCloudSteps; // Probably not needed

const float volumetricDepthInverse = 1.0 / VOLUMETRIC_CLOUD_DEPTH;
const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 0.5;
const float volumetricCloudHeight = 195.0 + volumetricCenterDepth;

// This is old now.
// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float rayReduction, in float dither){
    // Sets the bounding box vertically by creating an analytical slab intersected by a sphere at the camera's position
    float lowerSlabDist = (-VOLUMETRIC_CLOUD_DEPTH - cameraPos.y) / nFeetPlayerPos.y;
    float higherSlabDist = -cameraPos.y / nFeetPlayerPos.y;

    // Finds the slab entry and exit distances
    float slabNear = min(lowerSlabDist, higherSlabDist);
    float slabFar = max(lowerSlabDist, higherSlabDist);

    // Minimum cloud distance, if terrain, caps distance to the minimum cloud distance
    float sphereNear = 0.0;
    float sphereFar = min(volumetricCloudFar, feetPlayerDist);

    // Intersection of the slab and sphere here
    float marchStartDistance = max(slabNear, sphereNear);
    float marchEndDistance = min(slabFar, sphereFar);

    // Exit early when out of bounds
    if(marchEndDistance < marchStartDistance) return vec2(0);
    
    // inverse of the cloud far distance, used for fog calculation
    float invCloudFar = 1.0 / volumetricCloudFar;

    // Get distance inside the cloud
    float distInsideCloud = marchEndDistance - marchStartDistance;

    // Calculate steps that dynamically increase with distance
    // uint dynamicVolumetricCloudSteps = clamp(uint(distInsideCloud * rayReduction * volumetricCloudSteps), 1u, volumetricCloudSteps);
    uint dynamicVolumetricCloudSteps = uint(mix(1.0, volumetricCloudSteps, min(distInsideCloud * rayReduction / (distInsideCloud + 1.0), 1.0)));

    // Decide on this cuz this is driving me nuts

    // Multiply by dynamicVolumetricCloudStepsInv to get the step size and scale with distance
    float endDist = distInsideCloud / dynamicVolumetricCloudSteps;
    vec3 endPos = nFeetPlayerPos * endDist;

    // Camera position as its start position
    float startDist = marchStartDistance + endDist * dither;
    vec3 startPos = cameraPos + nFeetPlayerPos * marchStartDistance + endPos * dither;

    // To store the cloud data for 2 cloud layers
    vec2 cloudOutput = vec2(0);

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < dynamicVolumetricCloudSteps; i++){
        // Get cloud fog
        float cloudFog = 1.0 - startDist * invCloudFar;

        // Get cloud texture
        vec2 currCloudData = texelFetch(colortex0, ivec2(startPos.xz * 0.0625) & 255, 0).xy;

        // Apply cloud gradiante'
        // Check if ray is inside a cloud
        if(currCloudData.x > 0.5) cloudOutput.x = max(cloudOutput.x, -startPos.y * cloudFog);
        if(currCloudData.y > 0.5) cloudOutput.y = max(cloudOutput.y, -startPos.y * cloudFog);

        // Continue tracing
        startDist += endDist;
        startPos += endPos;
    }

    // Otherwise, return nothing
    return cloudOutput;
}

// My magnum opus, the ABSOLUTE Cinema, I present you...pure DDA traced clouds.
vec2 cloudsDDA(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist){
    // Original local slab: y in [-VOLUMETRIC_CLOUD_DEPTH, 0]
    float lowerSlabDist  = (-VOLUMETRIC_CLOUD_DEPTH - cameraPos.y) / nFeetPlayerPos.y;
    float higherSlabDist = (0.0 - cameraPos.y) / nFeetPlayerPos.y;

    // Create a slab as thick as VOLUMETRIC_CLOUD_DEPTH
    float slabNear = min(lowerSlabDist, higherSlabDist);
    float slabFar = max(lowerSlabDist, higherSlabDist);

    // Sphere bound (same as before, but with an epilipson to avoid z-fighting)
    const float sphereNear = 0.0;
    float sphereFar = min(volumetricCloudFar, feetPlayerDist * 1.015625);

    float marchStartDistance = max(slabNear, sphereNear);
    float marchEndDistance = min(slabFar, sphereFar);

    if(marchEndDistance < marchStartDistance) return vec2(0);

    float distInsideCloud = marchEndDistance - marchStartDistance;
    float invCloudFar = 1.0 / volumetricCloudFar;

    // Start position and distance in local cloud space
    float startDist = marchStartDistance;
    vec3 startPos = cameraPos + nFeetPlayerPos * marchStartDistance;

    const uint voxelSize = 16u;
    const float voxelScale = 1.0 / voxelSize;

    // Ray in voxel space
    float voxelDist = distInsideCloud * voxelScale;
    vec2 voxelPos = startPos.xz * voxelScale;

    // DDA setup in voxel space
    vec2 stepDir = sign(nFeetPlayerPos.xz);
    vec2 stepSizes = stepDir / nFeetPlayerPos.xz;
    vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(voxelPos)) / nFeetPlayerPos.xz;

    // Keep track of previous cloud data to complete the shells in the XZ plane
    float closestDist = 0.0;
    vec2 cloudOutput = vec2(0);
    vec2 prevCloudData = vec2(0);

    // Don't need to keep track of step count (?)
    while(closestDist < voxelDist){
        // Convert parametric > world distance
        float currDist = startDist + closestDist * voxelSize;

        // Sample cloud pixels (same texture, same indexing)
        vec2 currCloudData = texelFetch(colortex0, ivec2(voxelPos) & 255, 0).xy;

        // Cloud fog
        float cloudFog = 1.0 - currDist * invCloudFar;
        // Local vertical shading
        float currentPosY = cameraPos.y + nFeetPlayerPos.y * currDist;
        // Cloud shading
        float cloudShade = -currentPosY * cloudFog;

        // I'm so pro (2)
        if(currCloudData.x > 0.5 || prevCloudData.x > 0.5) cloudOutput.x = max(cloudOutput.x, cloudShade);
        if(currCloudData.y > 0.5 || prevCloudData.y > 0.5) cloudOutput.y = max(cloudOutput.y, cloudShade);

        // Record previous cloud data
        prevCloudData = currCloudData;

        // DDA step, onto the next voxel!
        closestDist = minOf(nextDist);
        vec2 stepAxis = vec2(equal(nextDist, vec2(closestDist)));

        nextDist += stepAxis * stepSizes;
        voxelPos += stepAxis * stepDir;
    }

    // Create a new slab to fill in missing backface (since voxel tracing skips tracing in-between boundries)
    float newSlabDist = min(lowerSlabDist, sphereFar);

    // Complete the bottom plane (I'm so pro 3)
    if(nFeetPlayerPos.y < 0.0){
        // Fog is really easy to calculate at this point
        float cloudFog = 1.0 - newSlabDist * invCloudFar;
        // Plane coordinates
        vec3 hitPos = cameraPos + nFeetPlayerPos * newSlabDist;
        // Sample cloud voxel
        vec2 currCloudData = texelFetch(colortex0, ivec2(hitPos.xz * voxelScale) & 255, 0).xy;
        // Cloud shading
        float cloudShade = -hitPos.y * cloudFog;

        // Only shade if voxel is filled
        if(currCloudData.x > 0.5) cloudOutput.x = max(cloudOutput.x, cloudShade);
        if(currCloudData.y > 0.5) cloudOutput.y = max(cloudOutput.y, cloudShade);
    }

    return cloudOutput;
}