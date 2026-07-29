// General cloud voxel size
const uint voxelSize = 16u;
const float voxelScale = 1.0 / voxelSize;

// My magnum opus, the ABSOLUTE Cinema, I present you...pure voxel traced DDA clouds.
vec2 voxelClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist){
    // Create 2 analytical slabs
    float nFeetPlayerPosInvY = 1.0 / nFeetPlayerPos.y;
    float lowerSlabDist  = (-CLOUD_THICKNESS - cameraPos.y) * nFeetPlayerPosInvY;
    float higherSlabDist = -cameraPos.y * nFeetPlayerPosInvY;

    // Create a slab as thick as CLOUD_THICKNESS
    float slabNear = min(lowerSlabDist, higherSlabDist);
    float slabFar = max(lowerSlabDist, higherSlabDist);

    // Sphere bound capped by terrain distance (with an epilipson to avoid z-fighting)
    const float sphereNear = 0.0;
    float sphereFar = min(cloudDistantFar, feetPlayerDist * 1.015625);

    // Intersection of the slab and sphere here
    float rayStartDistance = max(slabNear, sphereNear);
    float rayEndDistance = min(slabFar, sphereFar);

    // Exit early when out of bounds
    if(rayEndDistance < rayStartDistance) return vec2(0);

    // Get distance inside the cloud
    float distInsideCloud = rayEndDistance - rayStartDistance;
    // This is for fog calculation
    float invCloudFar = 1.0 / cloudDistantFar;

    // Start position and distance in local cloud space
    float startDist = rayStartDistance;
    vec3 startPos = cameraPos + nFeetPlayerPos * rayStartDistance;

    // Ray in voxel space
    float voxelDist = distInsideCloud * voxelScale;
    vec2 voxelPos = startPos.xz * voxelScale;

    // DDA setup in voxel space
    vec2 stepDir = sign(nFeetPlayerPos.xz);
    vec2 nFeetPlayerPosInvXZ = 1.0 / nFeetPlayerPos.xz;
    vec2 stepSizes = stepDir * nFeetPlayerPosInvXZ;
    vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(voxelPos)) * nFeetPlayerPosInvXZ;

    // Keep track of previous cloud data to complete the shells in the XZ plane
    float closestDist = 0.0;
    vec2 cloudOutput = vec2(0);
    vec2 prevCloudData = vec2(0);

    // Don't need to keep track of step count (..?)
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

        // I'm so pro
        // cloudOutput = max(cloudOutput, step(0.5, max(currCloudData, prevCloudData)) * cloudShade);
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

    // Complete the bottom plane (I'm so pro 2)
    if(nFeetPlayerPos.y < 0.0){
        // Fog is really easy to calculate at this point
        float cloudFog = 1.0 - newSlabDist * invCloudFar;
        // Plane coordinates
        vec3 planePos = cameraPos + nFeetPlayerPos * newSlabDist;
        // Sample cloud voxel
        vec2 currCloudData = texelFetch(colortex0, ivec2(planePos.xz * voxelScale) & 255, 0).xy;
        // Cloud shading
        float cloudShade = -planePos.y * cloudFog;

        // I'm so pro (3)
        // cloudOutput = max(cloudOutput, step(0.5, currCloudData) * cloudShade);
        if(currCloudData.x > 0.5) cloudOutput.x = max(cloudOutput.x, cloudShade);
        if(currCloudData.y > 0.5) cloudOutput.y = max(cloudOutput.y, cloudShade);
    }

    return cloudOutput;
}