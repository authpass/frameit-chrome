# Example configuration for frameit_chrome

This directory contains example configuration with one screenshot and
two output images.

`metadata/android` is the input directory with one screenshot, text and 
frame configuration.

`metadata/frame` is the output directory.

# Regenerate output

To run it against `metadata/android` download [frameit-frames](https://github.com/fastlane/frameit-frames) to `$HOME/frameit-frames` and run:

```shell script
pub global activate frameit_chrome
pub global run frameit_chrome --base-dir=metadata/android --frames-dir=$HOME/frameit-frames/latest
```

Make sure to check out the [readme for documentation](https://github.com/authpass/frameit-chrome).
