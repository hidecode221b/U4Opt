# U4Opt: Undulator plot for the optimization of period

## Introduction

The undulator is an insertion device used to generate the synchrotron radiation at the high flux density. The photon energy depends on the electron beam energy, harmonic number, undulator period, and K parameter which is based on the undulator period and magnetic field strength. The magnetic field strength is varied with the magnetic gap, magnet dimention, and magnetization. The flux from the undulator depends on the the electron beam current, total length and period of the undulator, harmonic number, and K parameter. The tunable K range is related with tunable energy range as well as flux range at a particular harmonic number. 

U4Opt discloses these complex relationship among the parameters above. Users comprehend the principle of the undulator at a glance in two plots and tune the periodic length manually.

## Background

The undulator period can be optimized in the plot based on the magnet type, gap, flux. To design the undulator specification in the synchrotron facility, U4Opt has been developed. The first prototype of the program is based on the Excel spreadsheet, and transfered to the macro in Igor Pro. Python code is now available for the basic undulator configuration. The coding is in progress, not well documented, but open for public for review. The original idea is from the talk of Dr. Markus Tischer - [DESY](https://photon-science.desy.de/research/technical_groups/undulators/group_members/index_eng.html) in the [ID23](https://aps.anl.gov/Magnetic-Devices/Workshops-Proceedings/ID-23) workshop.

## Specification

No emittance or energy spread are taken into account resulting in the single electron approximation. Further optimization should be performed in [SPECTRA](https://spectrax.org/spectra/) or [SRW](https://www.aps.anl.gov/Science/Scientific-Software/OASYS). No warranty in the results from U4Opt. 

### Setup

#### Python

Install Python3, and pip3 install numpy, scipy, PyQt5, matplotlib, reliability. 

> 'python3 main.py'

#### Igor Pro version 8 or 9 (tested)

Open the procedure file, then compile. Undulator is available in the macro menu. Select the plot in the popup menu of u4opt.

## References

### Theory

[Richard P. Walker](https://indico.ictp.it/event/a02011/contribution/1)

[Johannes Bahrdt](http://dx.doi.org/10.5170/CERN-2006-002.441)

### Magnets

[Magnet vs gap](https://doi.org/10.1016/S0168-9002(00)00544-1)

[APPLE-II](https://www.aps.anl.gov/files/APS-sync/lsnotes/files/APS_1418272.pdf)

### Examples

![Python_u4opt.PNG](/Images/Python_u4opt.PNG)

![IgorPro_undulator.PNG](/Images/IgorPro_undulator.PNG)


