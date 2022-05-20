# PL2303 Legacy Driver Updater

[![GitHub release](https://img.shields.io/github/release/johnstevenson/pl2303-legacy.svg?color=blue)](https://github.com/johnstevenson/pl2303-legacy/releases)
[![Continuous Integration](https://github.com/johnstevenson/pl2303-legacy/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/johnstevenson/pl2303-legacy/actions?query=branch:main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

- For authentic Prolific PL2303 HXA/XA and TA/TB microchips
- Supports Windows 10 (x86, x64) and Windows 11 (x64)

![Screenshot](screenshot.png)

Download [PL2303 Legacy Updater Setup][release]. This allows you to run the updater program (shown
above) and check that the driver works for your device. You are recommended to install this program
on your computer in case Windows Update changes your driver, or if you use multiple devices with
different driver requirements.


[codefix]:  https://www.ifamilysoftware.com/Prolific_PL-2303_Code_10_Fix.html
[family]:   https://www.ifamilysoftware.com/
[release]:  https://github.com/johnstevenson/pl2303-legacy/releases/latest

## Supplied drivers

The following legacy drivers are provided:

### PL2303 HXA/XA

| Version    | Date       | Support ended |
|------------|------------|---------------|
| 3.3.11.152 | 12-03-2010 | Windows 8     |

PL2303HXA and PL2303XA were phased out in 2012 due to counterfeit Chinese copies. Note that this
driver will only be installed if Prolific recognizes the microchip.

This driver supports older microchips (PL2303H, PL2303HX and PL2030X) but if it is not suitable
you can try the excellent [Prolific PL-2303 Code 10 Fix][codefix] program from
[Family Software][family], which uses an earlier driver version (3.3.2.102).

### PL2303 TA/TB

| Version   | Date       | Support ended |
|-----------|------------|---------------|
| 3.8.36.2  | 12-05-2020 | Windows 11    |

PL2303TA and PL2303TB were both recommended by Prolific as replacements for the above end-of-life
microchips. Unfortunately support for these ended with the release of Windows 11, presumably for the
same reasons. This driver can recognize non-Prolific microchips and will display a readable message
in Windows Device Manager.
