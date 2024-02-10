# U4Opt: Undulator plot for the period optimization

## Introduction

The undulator is an insertion device used to generate the synchrotron radiation at a higher flux density than that from the bending magnet radiation. The photon energy from the undulator depends on the `electron beam energy`, `harmonic number`, `undulator period`, and `K` parameter which is based on the `undulator period` and `magnetic field strength`. The `magnetic field strength` is varied with the `magnetic gap`, `magnet dimension`, and `magnetization`. The `flux` from the undulator depends on the the `electron beam current`, `total length`, `undulator period`, `harmonic number`, and `K`. The maximum `K` value is correlated with the lowest energy as well as highest `flux` at a particular `harmonic number`. The photon energy extends toward a high energy as the `harmonic number` increases at every odd harmonic number.

**U4Opt** discloses these complex relationship among the parameters above. Users comprehend the principle of the undulator at a glance in two plots and tune the periodic length interactively.

## Background

The `undulator period` can be optimized in the plot based on the `magnet type`, `gap`, `flux`. To design the undulator specification in the synchrotron facility, **U4Opt** has been developed. The first prototype of the program is based on the Excel spreadsheet, and transfered to the macro in Igor Pro. Python code is now available. The coding is in progress, not well documented, but open for public for review. 

The first concept of K-period plot originates from the talk of [Dr. Markus Tischer (DESY)](https://photon-science.desy.de/research/technical_groups/undulators/group_members/index_eng.html) in the [ID23](https://aps.anl.gov/Magnetic-Devices/Workshops-Proceedings/ID-23) workshop.

### Magnet

The magnetic configuration can be selected in the pop down list. Users can tune the parameters from the default values in either (a, b, c) or (Br, M, h) configuration. APPLE-II is based on the Br = 0.62 expirically. The other APPLE type can be tuned based on the magneti field measurement.

### Preset

Users can import and export the parameters as a preset (.dat).

### Non-linear effects

No emittance or energy spread are taken into account resulting in the single electron and Gaussian beam approximation. Further optimization should be conducted in [SPECTRA](https://spectrax.org/spectra/) or [SRW](https://www.aps.anl.gov/Science/Scientific-Software/OASYS). 

### Limitations

No warranty of U4Opt without errors. Python and Igor Pro work in the same manner, but Igor Pro runs faster than Python does. The data can be handled in Igor as a wave within the program and transformed in further analysis.

## Setup

### Python (tested in Windows and macOS)

Install Python3, and pip3 install numpy, scipy, PyQt5, matplotlib, and reliability. 

```
python3 main.py
pip3 install numpy
pip3 install scipy
pip3 install pyqt5
pip3 install matplotlib
pip3 install reliability
```

### [Igor Pro](https://www.wavemetrics.com/) version 8 or 9 (tested in Windows and macOS)

Open the procedure file, then compile it. Undulator is available in the macro menu. Select the plot in the popup menu of **U4Opt** interface.

## References

### Theory of the undulalar

- [Richard P. Walker](https://indico.ictp.it/event/a02011/contribution/1)

- [Johannes Bahrdt](http://dx.doi.org/10.5170/CERN-2006-002.441)

- [Jui-Che Huang](https://doi.org/10.1103/PhysRevAccelBeams.20.064801)

### Magnet parameters

- [Magnet vs gap](https://doi.org/10.1016/S0168-9002(00)00544-1)

- [APPLE-II](https://www.aps.anl.gov/files/APS-sync/lsnotes/files/APS_1418272.pdf)

## Interface

### Python (adjustable period shown as a pink marker)

![Python_u4opt.PNG](/Images/Python_u4opt.PNG)

### Igor Pro (2D plot can be either contour or image, not only energy but also flux, etc.)

![IgorPro_undulator.PNG](/Images/IgorPro_undulator_interface.PNG)

### Igor Pro (adjustable period shown as a cross hair)

![IgorPro_undulator.PNG](/Images/IgorPro_undulator1.PNG)


