# Conceal

A World of Warcraft Addon to hide UI Elements when not in use.

## Developing

When developing locally you need to clone [the BigWigs Packager repo](https://github.com/BigWigsMods/packager) into the gitignored folder `./.release`. Its `release.sh` script should then be used for building the correct version of the addon, and can also be used to build+release it to Curseforge, Wago, Wowinterface etc.

```shell
git clone git@github.com:BigWigsMods/packager.git .release
```

```shell
.release/release.sh --help

Usage: release.sh [options]
  -c               Skip copying files into the package directory.
  -d               Skip uploading.
  -e               Skip checkout of external repositories.
  -l               Skip @localization@ keyword replacement.
  -L               Only do @localization@ keyword replacement (skip upload to CurseForge).
  -o               Keep existing package directory, overwriting its contents.
  -s               Create a stripped-down "nolib" package.
  -S               Create a package supporting multiple game types from a single TOC file.
  -u               Use Unix line-endings.
  -z               Skip zip file creation.
  -t topdir        Set top-level directory of checkout.
  -r releasedir    Set directory containing the package directory. Defaults to "$topdir/.release".
  -p curse-id      Set the project id used on CurseForge for localization and uploading. (Use 0 to unset the TOC value)
  -w wowi-id       Set the addon id used on WoWInterface for uploading. (Use 0 to unset the TOC value)
  -a wago-id       Set the project id used on Wago Addons for uploading. (Use 0 to unset the TOC value)
  -g game-version  Set the game version to use for uploading.
  -m pkgmeta.yaml  Set the pkgmeta file to use.
  -n "{template}"  Set the package zip file name and upload label. Use "-n help" for more info.
```

### Examples:

```shell
# Builds for retail, downloads dependencies (libs), zips and then uploads the release (if you have env variables specified)
.release/release.sh
```

```shell
# Build for retail, dont release, dont download libs, dont zip
.release/release.sh -d -e -z
```

```shell
# The -g <version> specifies target to build for.

# Build for WOTLK, dont release, dont zip, dont download libs
.release/release.sh -d -e -z -g wrath
```

```shell
# Copy your build to your installed wow location
cp -rf .release/Conceal "Your/Wow/Dir/Interface/Addons"
```

## Releasing

Push a tag `1.2.3` to trigger the Github Actions workflow to create a release called `1.2.3`

It will build the app for retail, classic, tbc classic and wotlk classic and then upload them as artifacts on a github release of the same version.
