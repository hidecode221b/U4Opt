# U4Opt: Undulator plot for the optimization of period

## Introduction

The undulator is an insertion device used to generate the synchrotron radiation at the high flux density. The photon energy depends on the electron beam energy, harmonic number, undulator period, and K parameter which is based on the undulator period and magnetic field strength. The magnetic field strength is varied with the magnetic gap, magnet dimention, and magnetization. The flux from the undulator depends on the the electron beam current, total length and period of the undulator, harmonic number, and K parameter. The tunable K range is related with tunable energy range as well as flux range at a particular harmonic number. 

U4Opt discloses these complex relationship among the parameters above. Users comprehend the principle of the undulator at a glance in two plots and tune the periodic length manually.

## Background

The undulator period can be optimized in the plot based on the magnet type, gap, flux. To design the undulator specification in the synchrotron facility, U4Opt has been developed. The first prototype of the program is based on the Excel spreadsheet, and transfered to the macro in Igor Pro. Python code is now available for the basic undulator configuration. The coding is in progress, not well documented, but open for public for review.
