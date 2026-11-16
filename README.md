![Thumbnail](https://github.com/Eldeston/Super-Duper-Vanilla/blob/master/shaders/textures/thumbCF.png?raw=true)
![Title Logo](https://github.com/Eldeston/Super-Duper-Vanilla/blob/master/shaders/textures/title.png?raw=true)
[![Discord](https://img.shields.io/discord/604061216779796492?style=for-the-badge&logo=discord&logoColor=white&label=FlameRender%C2%A9%20Studios&labelColor=7289DA)](https://discord.gg/UE85W5ynCg)
![CurseForge Downloads](https://img.shields.io/curseforge/dt/534748?style=for-the-badge&logo=curseforge&logoColor=%23FFFFFF&label=CurseForge%20Downloads&color=%23FF9101)
![Modrinth Downloads](https://img.shields.io/modrinth/dt/LMIZZNxZ?style=for-the-badge&logo=modrinth&logoColor=%23FFFFFF&label=Modrinth%20Downloads&color=%2300FF00)

## Description
Super Duper Vanilla is a Minecraft shader pack created to convey the cancelled __Super Duper Graphics Pack__ and other popular Minecraft titles. Developed by [@Eldeston](https://github.com/Eldeston) and presented by __FlameRender Studios__.

## Shader Overview
SDV brings a PBR-focused take on Minecraft, pairing dynamic lighting with atmospheric effects and a deep set of visual options. Features include SSAO/SSR and experimental SSGI, voxel clouds and volumetric lighting, anti-aliasing, motion blur, depth of field, bloom, and tone mapping. See [Mod Compatibility](#mod-compatibility) for integrations.

For the rendering pipeline, settings, buffers, program map, and implementation references, see [DOCUMENTATION.md](DOCUMENTATION.md).

## Sponsored by BisectHosting
[![Sponsor](https://github.com/Eldeston/Super-Duper-Vanilla/blob/master/shaders/textures/sponsor0.png?raw=true)](https://bisecthosting.com/FLAMERENDERSTUDIOS)
This shader is sponsored by **BisectHosting**. Open the image above or use the code [**FLAMERENDERSTUDIOS**](https://bisecthosting.com/FLAMERENDERSTUDIOS) to claim your discount to get ***25%*** off on your first month!

Choose **BisectHosting** to host a wide range of games including some of my personal favorites: **Minecraft, Terraria, and Project Zomboid**! ***65%*** of your first purchase will support the development of Super Duper Vanilla!

## Sponsored by Ember Host
[![Sponsor](https://github.com/Eldeston/Super-Duper-Vanilla/blob/master/shaders/textures/sponsor1.png?raw=true)](https://billing.ember.host/aff.php?aff=23)
This shader is sponsored by **Ember Host**. Open the image above or use the code [**SUPERFLAME**](https://billing.ember.host/aff.php?aff=23) to claim your discount to get ***10%*** off on your first purchase!

Choose **Ember Host** to host your Minecraft server and take advantage of their **powerful AMD processors** and go beyond with excellent prices! ***70%*** of your first purchase will support the development of Super Duper Vanilla!

## Screenshots
![2022-06-28_19 28 13](https://cdn.modrinth.com/data/LMIZZNxZ/images/bd57c68a400e0722bc7132575ea7cec66ca529ab.png)
![2022-06-28_19 43 18](https://cdn.modrinth.com/data/LMIZZNxZ/images/1d38424b62d4461fae738019cbd1342145e9b4ac.png)
![2022-06-28_19 49 58](https://cdn.modrinth.com/data/LMIZZNxZ/images/8edcb53225f8eeade023759c54df0916d9e3ff2a.png)
![2022-07-04_20 31 16](https://cdn.modrinth.com/data/LMIZZNxZ/images/79de640c0254dd1f8ddf44052a79b57105a53f2c.png)
![2022-07-04_20 36 15](https://cdn.modrinth.com/data/LMIZZNxZ/images/33a5e8c49e4a386c17a42ef48d96f240fa8e7d20.png)
![2022-07-04_20 37 21](https://cdn.modrinth.com/data/LMIZZNxZ/images/f97e5cb26647bd487fae153b9942f87f373f7695.png)
![2022-07-04_20 38 41](https://cdn.modrinth.com/data/LMIZZNxZ/images/7735240a7238b15b28dba555abf0cd03f798823a.png)
![2022-07-04_20 40 49](https://cdn.modrinth.com/data/LMIZZNxZ/images/f643695cdd4ab9f7c95750fb8ff43f396cd16f6c.png)
![2022-07-04_20 42 13](https://cdn.modrinth.com/data/LMIZZNxZ/images/8e152465e03a3861acf4a7be6eca82a86cf26f1a.png)
![2022-07-04_20 49 54](https://cdn.modrinth.com/data/LMIZZNxZ/images/0126040f5bcc1828e2de2b059799ab7ffb3d08ec.png)

## License
This shader pack is distributed under the **FlameRender (C) Studios License**. See [LICENSE](LICENSE) for details.

## Contribution
If you plan to contribute to this project, see [**CONTRIBUTION**](CONTRIBUTION.md) for more info.

## Compatibility and Support
Current builds target Iris. The table summarizes the published Minecraft version and platform compatibility; OptiFine entries are retained from the older README table and are historical only.

| Loader | Minecraft version | Windows/Linux (Intel, AMD, NVIDIA) | Apple M1 |
|---|---|---|---|
| Iris 1.6.10+ | 1.18.2 and later | Supported | Supported |
| Iris | 1.17.1 and earlier | Not supported | Not supported |
| OptiFine (historical) | 1.17.1 and later | Partial support | Partial support |
| OptiFine (historical) | 1.14.2 and later | Partial support | Not supported |
| OptiFine (historical) | 1.13.2 and earlier | Not supported | Not supported |

OptiFine maintenance ended with SDV 1.3.7 and officialy incompatible by 1.4.0. Older AMD graphics drivers may show visual issues. Pojav Launcher use is unofficial, and results vary by device. For detailed compatibility notes, see [DOCUMENTATION.md](DOCUMENTATION.md).

## Mod Compatibility

SDV includes shader paths for several popular mods. Here is what those integrations cover:

| Mod | Integration in SDV |
|---|---|
| Distant Horizons | Dedicated programs for distant terrain, generic geometry, and water. |
| Voxy | Voxy depth inputs in rendering paths that support them. |
| Physics Mod | Ocean geometry and shadow rendering. |
| Astrocraft, Nuit | Low-priority visual issues. Will likely remain unimplemented. |

Missing a mod you use? Open an issue and link its project page. If you are adding support yourself, test the relevant paths and follow [CONTRIBUTION.md](CONTRIBUTION.md).

## Releases
Browse every release on the [GitHub releases page](https://github.com/Eldeston/Super-Duper-Vanilla/releases). Development builds live on their corresponding branches; switch to the branch you want, select **Code**, and choose **Download ZIP**.

Latest build and pre-release versions are expected to be unstable, please report any issues or bugs anytime. Feedback is much appreciated.

## Official Modrinth Page
Super Duper Vanilla just happens to be on Modrinth! Stable and latest releases will always be available there. Check it out [here](https://modrinth.com/shader/super-duper-vanilla) and support me by using any one of the download links there!

## Official CurseForge Page
Super Duper Vanilla is also on CurseForge! Stable and latest releases will always be available there. Check it out [here](https://www.curseforge.com/minecraft/customization/super-duper-vanilla-shaders) and support me by using any one of the download links there!

## Super Duper Vanilla Installer
Prefer an installer? The [Super Duper Vanilla Installer](https://github.com/steb-git/super-duper-vanilla-installer), developed by [@steb-git](https://github.com/steb-git), can install release or development builds. It is still a work in progress.

## Social Links
Come join the FlameRender Studios community on Discord to chat about SDV and other projects:
* [Flamerender Studios Discord](https://discord.gg/UE85W5ynCg)

Follow [@Eldeston on X](https://twitter.com/eldeston) or subscribe to the [YouTube channel](https://www.youtube.com/channel/UCQCkkFh25ydxZwCqpBhJJlg?view_as=subscriber) for development updates and new videos.

You can support the project through [PayPal](https://www.paypal.com/donate?hosted_button_id=4XLQ4WE296JKW), too.