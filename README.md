<p align="center"> 
  <img src="art/icons/logo_cropped.png" width="400">
  
  # Vs. Dave & Bambi
  A Friday Night Funkin' mod powered by Dave Engine!
  [Download the mod](https://gamebanana.com/mods/43201)
  
  <table>
    <tr>
      <td><<img src="https://images.gamebanana.com/img/ss/mods/68b38f18b5077.jpg" width=300></td>
      <td><img src="https://images.gamebanana.com/img/ss/mods/68b38f1a6da7f.jpg" width=300></td>
      <td><img src="https://images.gamebanana.com/img/ss/mods/68b38f2037438.jpg" width=300></td>
    </tr>
  </table>
</p>

## Dave Engine
Dave Engine is an engine that started out as originally a Kade Engine modification, but has since
turned into its own complete separate engine! This engine contains many powerful features including:

- Modding Support [via Polymod](https://polymod.io/)
- Script Events powered by HScript
- Custom Character Select
- Language Support
- Custom Runtime OpenGL Shaders
- Many more!

## Compiling
Inside the project's root folder, you'll see 2 files:
- **libraries_install.bat**
- **libraries_update.bat**

Run **libraries_install.bat** to install all of the necessary libraries needed to compile the project. 

_If you're on Mac or Linux, open your platform's Command Line and do the following commands:_
- haxelib install hmm
- haxelib run hmm setup
- hmm install

## Modding
If you're interested in modding Vs. Dave & Bambi, feel free to read the [official documentation!](https://docs.daveandbambi.net/)

## Contributing
TODO.

## Android Support
I ported Dave And Bambi's Volume 1 to Android 2 days after the source code was released.

Please Playtest this: https://drive.google.com/file/d/1x29g3fiwA-xXEyO3HlX9t3Ul7EYoDP-m/view?usp=sharing
Share bugs via the Issues tab, this will help alot during the port.

Anyways, if you see this:
[Screenshot](https://media.discordapp.net/attachments/1323021749973024768/1444804638665736312/Screenshot_2025-11-30_213549.png?ex=692eb36d&is=692d61ed&hm=051d1e2fa700770711536a4236daf803160b5e361d4e6c0576e6cfaf77c221f6&=&format=webp&quality=lossless&width=1426&height=800)

That means the app has installed successfully, but needs to do certain steps to actually play the game.

Steps to play:
1. Download a file explorer, I'd recommend to install [ZArchiver](https://play.google.com/store/search?q=zarchiver&c=apps&pli=1)
2. Go to the directory you downloaded the apk in
3. Tap on it, then tap view. It should show this: [Screenshot](https://media.discordapp.net/attachments/1323021749973024768/1444810573505237093/Screenshot_20251130-140053.ZArchiver2.png?ex=692eb8f4&is=692d6774&hm=9306447e712bdcc31695058a163797c311a230bbc18eee05cba0fb8f10db524f&=&format=webp&quality=lossless&width=900&height=918)
3. Go inside the assets folder, then copy the "assets" folder. (Yes, there are two assets folder).
4. Copy and paste this to "/storage/emulated/0/Android/media/dnbteam.daveandbambi/" (or "Android/media/dnbteam.daveandbambi/").
5. Restart the app. it should work!