# frameit_chrome

Embed app store and play store screenshots in device frames. 
Drop in replacement for fastlane frameit.

It uses a simple dart script to locate localized screenshots and parses
`title.strings` and `keyword.strings` and uses **chrome headless**
to render the screenshot with some css and html magic.

# Create screenshots

Use any tool to create non-framed screenshots, for flutter I've used
[screenshots package](https://pub.dev/packages/screenshots).

# Usage

* Download device frames from https://github.com/fastlane/frameit-frames
* Place your screenshots into file hierarchy as used by fastlane.
  ```
  android/
    android/metadata
      android/metadata/android/de-DE
      android/metadata/android/de-DE/images
      android/metadata/android/de-DE/images/samsung-galaxy-s10-plus-password_generator.png
  ```
  * (the above example has `<basedir>` = `android/metadata/android`):
  * Screenshots into `<basedir>/<locale>/images/`
  * a `title.strings` and `keyword.strings` into `<basedir>/<locale>/`
  * example `title.strings` (key must match part of the file name of the screenshot):
    ```
 "password_generator" = "Great password generator!";
    ```
* Run `frameit_chrome.dart`:
  ```shell
  dart bin/frameit_chrome.dart --base-dir=/myproject/fastlane/metadata/android --frames-dir=path-to-downloaded/frameit-frames/latest --chrome-binary="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  ```

# Example

Small example how localized [AuthPass](https://authpass.app) screenshots look like ;-)

[![Example Screenshot](./_docs/example.png)](./_docs/example.png)

# TODO

* Run from `pub global`
* Allow more customizations
  * Frame screenshot overrides.
  * CSS customizations.
