## Basic Guidelines
   Important standards that must be followed when contributing to this project. These guidelines must remain consistent wherever possible. Please also read [DOCUMENTATION.md](DOCUMENTATION.md) for information about the current pipeline.

* Do not submit your pull request without testing the shader.
* Optimize your code wherever possible, leave comments when necessary.
* If you're making a pull request for mod compatibility, make sure it follows the above guidelines.

## Translation
   For translation, it should be based from the latest commit to ensure compatibility and avoid conflicts, and that another person fluent of the language you're translating to should verify the final product. Please also update to the latest .lang version format as the main language file [en_US](/lang/en_US.lang).

   If you're updating an existing translation, the same rules will apply unless someone is already working on it. If that were the case, please communicate with the user working on the translation before making a pull request.
   
## Format guidelines
   No spaces around parentheses: `if(condition){`, `this = function()`

```glsl
vec3 neverGonna(vec3 GiveYouUp){
   if(neverGonnaLetYouDown){
      return neverGonnaRunAroundAndDesertYou;
   }else if(neverGonnaMakeYouCry){
      return neverGonnaSayGoodBye;
   }

   return neverGonnaRunAroundAndDesertYou;
}
```

   Use `SCREAMING_CASE` for defined macros only.

```glsl
#define THIS_IS_CORRECT 0.0

#define this_is_incorrect 0.0
```

   Use `camelCase` on everything else.

```glsl
struct thisIsCorrect{
   vec3 thisIsAlsoCorrect;
   float thisIsAlsoCorrectAsWell;
}

thisIsCorrect thisIsAlsoCorrect(vec3 THIS_IS_INCORRECT){
   const float thisIsVeryCorrect = 1.0;
   thisIsCorrect this_is_incorrect(vec3(0), thisIsVeryCorrect);
   return this_is_incorrect;
}
```

   When commenting, leave a space after `//` or `/*`.

```glsl
// This is a comment.
/* Explain your code here. */

/*
Is this a bird?
*/

//This is not a comment
/*BLASPHEMY!*/
```

## Miscellaneous
   You may add your name in [**CONTRIBUTORS**](CONTRIBUTORS.md) under the contributers list with your PR. If you're a translator, add your name in [**TRANSLATORS**](TRANSLATORS.md) under the translators list.

## TO DO (for Eldeston)
   * Update the descriptions of this file.
   * Make a separate file for translation.