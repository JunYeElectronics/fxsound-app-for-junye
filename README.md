# FxSound for J&Y Audio

FxSound is a digital audio program built for Windows PC's. The background processing, built on a high-fidelity audio engine, acts as a sort of digital soundcard for your system. This means that your signals will have the clean passthrough when FxSound is active. There are active effects for shaping and boosting your sound's volume, timbre, and equalization included on top of this clean processing, allowing you to customize and enhance your sound.

This is a customized build of FxSound maintained by **Jun Ye Electronics (J&Y Audio)** for use with our audio products.

## General Information
* Company: [Jun Ye Electronics](https://www.jun-ye.com)
* Source code: https://github.com/JunYeElectronics/fxsound-app-for-junye
* Issue tracker: https://github.com/JunYeElectronics/fxsound-app-for-junye/issues
* Original project: [fxsound2/fxsound-app](https://github.com/fxsound2/fxsound-app)

## Build Instructions
### Prerequisites
* Download and install the [latest version of FxSound](https://download.fxsound.com/fxsoundlatest)
* Install [Visual Studio 2022](https://visualstudio.microsoft.com/vs)
* Install [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk)
* Install [JUCE 6.1.6](https://github.com/juce-framework/JUCE/releases/tag/6.1.6) for x64/x86
* Install [Latest JUCE framework](https://api.juce.com/api/v1/download/juce/latest/windows) for ARM64

FxSound application requires FxSound Audio Enhancer virtual audio driver. So, to run FxSound application built from source, we need to install FxSound which installs the audio driver.

### Build FxSound from Visual Studio
* Open [fxsound/Project/FxSound.sln](https://github.com/JunYeElectronics/fxsound-app-for-junye/blob/main/fxsound/Project/FxSound.sln) in Visual Studio
* Build the required configuration and platform and run

### Build after exporting the project form Projucer
FxSound application has three components. 
1. FxSound GUI application which uses JUCE framework
2. Audiopassthru module which is used by the application to interact with the audio devices
3. DfxDsp module which is the DSP for processing audio

Due to the some limitations with Projucer, after exporting the Visual Studio solution from Projucer, few changes have to be made in the solution to build FxSound.
1. Since the audiopassthru and DfxDsp dependency projects cannot be added to the solution when FxSound.sln is exported, open fxsound/Project/FxSound.sln in Visual Studio and add the existing projects audiopassthru/audiopassthru.vcxproj, dsp/DfxDsp.vcxproj.
2. From FxSound_App project, add reference to audiopassthru and DfxDsp.
3. If you run FxSound from Visual Studio, to let the application to use the presets, set the Working Directory to ```$(SolutionDir)..\..\bin\$(PlatformTarget)``` in FxSound_App Project->Properties->Debugging setting.

## How to contribute
We welcome anyone who wants to contribute to this project. For more details on how to contribute, follow [this contributing guideline](./CONTRIBUTING.md).

## Acknowledgements
This project is based on [FxSound](https://github.com/fxsound2/fxsound-app) by FxSound LLC.

Our special thanks to Advanced Installer for supporting us with Advanced Installer Professional license to build our installer.

[![image](https://github.com/user-attachments/assets/c133fe06-619c-4c17-bce9-f1cf051c5265)](https://www.advancedinstaller.com)

This project uses the [JUCE](https://juce.com) framework, which is licensed under [AGPL v3.0](https://github.com/juce-framework/JUCE/blob/master/LICENSE.md).

Thanks to [Theremino](https://www.theremino.com) for the valuable contributions they do through major feature enhancements in FxSound.

## License
[AGPL v3.0](https://github.com/JunYeElectronics/fxsound-app-for-junye/blob/main/LICENSE)

This project is licensed under the GNU Affero General Public License v3.0. The original copyright belongs to FxSound LLC. See the [LICENSE](./LICENSE) file for full details.
