/* -------- Resolver -------- */

// Set WORLD_PREFIX per dimension before including this resolver:
//   Overworld (0): WORLD0
//   End (1):       WORLD1
//   Nether (-1):   WORLDn1

#define _WORLD_CONCAT(prefix, suffix) prefix##suffix
#define WORLD_CONCAT(prefix, suffix) _WORLD_CONCAT(prefix, suffix)
#define W_SYM(suffix) WORLD_CONCAT(WORLD_PREFIX, suffix)

/* ----- World Flags ----- */

// #ifdef W_SYM(_SKYBOX)
//     #define WORLD_SKYBOX
// #endif

// #ifdef W_SYM(_CLOUDS)
//     #define WORLD_CLOUDS
// #endif

// #ifdef W_SYM(_WEATHER)
//     #define WORLD_WEATHER
// #endif

// #ifdef W_SYM(_DAYCYCLE)
//     #define WORLD_DAYCYCLE
// #endif

// #ifdef W_SYM(_SKYLIGHT)
//     #define WORLD_SKYLIGHT
// #endif

/* ----- Shader Flags ----- */

// #ifdef W_SYM(_LIGHT)
//     #define WORLD_LIGHT
// #endif

// #ifdef W_SYM(_STARS)
//     #define WORLD_STARS
// #endif

// #ifdef W_SYM(_AETHER)
//     #define WORLD_AETHER
// #endif

// #ifdef W_SYM(_SKYGROUND)
//     #define WORLD_SKYGROUND
// #endif

// #ifdef W_SYM(_VANILLAFOG)
//     #define WORLD_VANILLAFOG
// #endif

/* ----- Basic Config ----- */

#define WORLD_CELESTIAL W_SYM(_CELESTIAL)
#define WORLD_CELESTIAL_SIZE W_SYM(_CELESTIAL_SIZE)
#define WORLD_VANILLAFOG_MODE W_SYM(_VANILLAFOG_MODE)
#define WORLD_SKYLIGHT_OVERRIDE W_SYM(_SKYLIGHT_OVERRIDE)

/* ----- Star Config ----- */

#define WORLD_STAR_DI W_SYM(_STAR_DI)
#define WORLD_STAR_TI W_SYM(_STAR_TI)
#define WORLD_STAR_NI W_SYM(_STAR_NI)

/* ----- Light Config ----- */

#define WORLD_LIGHT_CR W_SYM(_LIGHT_CR)
#define WORLD_LIGHT_CG W_SYM(_LIGHT_CG)
#define WORLD_LIGHT_CB W_SYM(_LIGHT_CB)
#define WORLD_LIGHT_CI W_SYM(_LIGHT_CI)

#define WORLD_LIGHT_DR W_SYM(_LIGHT_DR)
#define WORLD_LIGHT_DG W_SYM(_LIGHT_DG)
#define WORLD_LIGHT_DB W_SYM(_LIGHT_DB)
#define WORLD_LIGHT_DI W_SYM(_LIGHT_DI)

#define WORLD_LIGHT_TR W_SYM(_LIGHT_TR)
#define WORLD_LIGHT_TG W_SYM(_LIGHT_TG)
#define WORLD_LIGHT_TB W_SYM(_LIGHT_TB)
#define WORLD_LIGHT_TI W_SYM(_LIGHT_TI)

#define WORLD_LIGHT_NR W_SYM(_LIGHT_NR)
#define WORLD_LIGHT_NG W_SYM(_LIGHT_NG)
#define WORLD_LIGHT_NB W_SYM(_LIGHT_NB)
#define WORLD_LIGHT_NI W_SYM(_LIGHT_NI)

/* ----- Sky Config ----- */

#define WORLD_SKY_CR W_SYM(_SKY_CR)
#define WORLD_SKY_CG W_SYM(_SKY_CG)
#define WORLD_SKY_CB W_SYM(_SKY_CB)
#define WORLD_SKY_CI W_SYM(_SKY_CI)

#define WORLD_SKY_DR W_SYM(_SKY_DR)
#define WORLD_SKY_DG W_SYM(_SKY_DG)
#define WORLD_SKY_DB W_SYM(_SKY_DB)
#define WORLD_SKY_DI W_SYM(_SKY_DI)

#define WORLD_SKY_TR W_SYM(_SKY_TR)
#define WORLD_SKY_TG W_SYM(_SKY_TG)
#define WORLD_SKY_TB W_SYM(_SKY_TB)
#define WORLD_SKY_TI W_SYM(_SKY_TI)

#define WORLD_SKY_NR W_SYM(_SKY_NR)
#define WORLD_SKY_NG W_SYM(_SKY_NG)
#define WORLD_SKY_NB W_SYM(_SKY_NB)
#define WORLD_SKY_NI W_SYM(_SKY_NI)

/* ----- Fog Config ----- */

#define WORLD_FOG_TOTAL_CI W_SYM(_FOG_TOTAL_CI)
#define WORLD_FOG_TOTAL_DI W_SYM(_FOG_TOTAL_DI)
#define WORLD_FOG_TOTAL_NI W_SYM(_FOG_TOTAL_NI)
#define WORLD_FOG_TOTAL_TI W_SYM(_FOG_TOTAL_TI)

#define WORLD_FOG_VERTICAL_CI W_SYM(_FOG_VERTICAL_CI)
#define WORLD_FOG_VERTICAL_DI W_SYM(_FOG_VERTICAL_DI)
#define WORLD_FOG_VERTICAL_NI W_SYM(_FOG_VERTICAL_NI)
#define WORLD_FOG_VERTICAL_TI W_SYM(_FOG_VERTICAL_TI)