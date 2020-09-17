# frameit_chrome

Embed app store and play store screenshots in device frames. 
Drop in replacement for fastlane frameit.

It uses a simple dart script to locate localized screenshots and parses
`title.strings` and `keyword.strings` and uses **chrome headless**
to render the screenshot with some css and html magic.

[![Example Screenshot](./_docs/example.png)](./_docs/example.png)

* (Screenshots from [AuthPass Password Manager](https://authpass.app/))

# Requirements

* Dart 😅️ (for now)
* Google Chrome executable. By default, will look into 
    `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
    (tested with Chrome 86.0.4240.30).
* Screenshots and Device Frames.

# Usage

## Create screenshots

Use any tool to create non-framed screenshots, for flutter I've used
[screenshots package](https://pub.dev/packages/screenshots).

## Download device frames
 
Download device frames from https://github.com/fastlane/frameit-frames
 to `$HOME/frameit-frames`.

## Folder hierarchy

Place your screenshots into file hierarchy as used by fastlane.

```bash
metadata/
  android/ # <-- `--base-dir` argument
    en-US/
      <device-name>-<screenshot-name>.png
      samsung-galaxy-s10-plus-password_generator.png # Example
      title.strings
      keyword.strings (optional)
    de-DE/
      <device-name>-<screenshot-name>.png
      samsung-galaxy-s10-plus-password_generator.png # Example
      title.strings
      keyword.strings (optional)
    frameit.yaml (optional)
  framed/ # <-- output directory
  ```

* In the above example: `<base-dir>` = `metadata/android`
* Put Screenshots into `<base-dir>/<locale>/images/`
* a `title.strings` and `keyword.strings` into `<base-dir>/<locale>/`
* example `title.strings` (key must match part of the file name of the screenshot):
    ```
 "password_generator" = "Great password generator!";
    ```

## Install `frameit_chrome`

```shell script
pub global activate frameit_chrome
```

## Run `frameit_chrome.dart`:

(Assumes [frameit-frames](https://github.com/fastlane/frameit-frames) downloaded to `$HOME/frameit-frames`)

```shell script
pub global run frameit_chrome --base-dir=/myproject/fastlane/metadata/android --frames-dir=$HOME/frameit-frames/latest
```

On non-mac platforms or when you've installed Google Chrome in non-default location:

```shell script
pub global run frameit_chrome --base-dir=/myproject/fastlane/metadata/android --frames-dir=$HOME/frameit-frames/latest --chrome-binary="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

# Example

See the [Example Directory](./example/README.md) as well as usage of AuthPass:

* Android: https://github.com/authpass/authpass/tree/master/authpass/android/fastlane/metadata/android
* iOS: https://github.com/authpass/authpass/tree/master/authpass/ios/fastlane/screenshots

# TODO

* Allow more customizations
  * Frame screenshot overrides.
  * CSS customizations.
