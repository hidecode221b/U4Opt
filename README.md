# U4Opt: Undulator plot for the period optimization

## Introduction

The undulator is an insertion device used to generate the synchrotron radiation at a higher flux density than that from the bending magnet radiation. The photon energy ($hc/\lambda$) from the undulator depends on the electron beam energy ($0.000511\gamma$ GeV), harmonic number ($n$), undulator period ($\lambda_u$), polar angle from the undulator axis ($\theta$), and $K$ parameter which is based on the $\lambda_u$ and magnetic field strength ($B_0$). 

$$\lambda_n = {\lambda_u \over 2 n \gamma^2}\left( 1 + {K^2 \over 2} + \gamma^2 \theta^2 \right)$$

$$K = {e B_0 \lambda_u \over 2 \pi m c^2}$$


$B_0$ can be designed in the magnet height ($h$) and magnetization ($B_r$), and tuned in the magnetic gap ($g$) and temperature. The minimum gap is basically limited in the dynamic aperture of the storage ring lattice, and the maximum gap is limited in the mechanical structure of the undulator. Various magnetic types and structures are available in the advanced synchrotron facilities. 


The  flux ($F$) from the undulator depends on the the electron beam current ($I$ amps), total length ($L$), $\lambda_u$, $n$, and $K$. The flux over the central cone ($\sqrt{\lambda/L}$) at the harmonic $n$ and number of periods $N$ ($=L/\lambda_u$) in the band width ($\Delta \omega/\omega=0.1$ \%) is

$${\partial F \over \partial (\Delta \omega/\omega)} = 1.744 \cdot 10^{14} \cdot N \cdot Q_n(K) \cdot I$$

$$Q_n(K) = (1+K^2/2) \cdot F_n(K)/n$$

$$F_n(K) = {K^2n^2 \over (1 + K^2/2)^2} \cdot \left[ \ J_{n-1 \over 2}(\zeta) - J_{n+1 \over 2}(\zeta) \right]\^2$$

$$\zeta = {nK^2 \over 4 (1 + K^2/2)}$$

$J$ represents the [Bessel junction of the first kind](https://en.wikipedia.org/wiki/Bessel_function).


The maximum $K$ value is correlated with the lowest energy as well as highest $F$ at a particular $n$. The photon energy extends toward a high energy as the $n$ increases at every odd $n$. However, the energy is not tunable between 1st and 3rd harmonics if $K$ is less than 2, because the wavelength of radiation $\lambda_1$ at $K=0$ is equal to $\lambda_3$ at $K=2$ on axis $\theta = 0$ as shown below.

$$\lambda_{1, K=0} = {\lambda_u \over 2 \cdot 1 \gamma^2} \left( 1 + {0^2 \over 2} \right) = {\lambda_u \over 2 \gamma^2}$$

$$\lambda_{3, K=2} = {\lambda_u \over 2 \cdot 3 \gamma^2} \left( 1 + {2^2 \over 2} \right) = {\lambda_u \over 2 \gamma^2}$$


**U4Opt** discloses these complex relationship among the parameters above. Users comprehend the principle of the undulator at a glance in two plots and tune the periodic length interactively.



## Background

The `undulator period` can be optimized in the plot based on the `magnet type`, `gap`, `flux`. To design the undulator specification in the synchrotron facility, **U4Opt** has been developed. The first prototype of the program is based on the Excel spreadsheet, and transfered to the macro in Igor Pro. Python code is now available. The coding is in progress, not well documented, but open for public for review. 

The first concept of `K-period` space analysis originates from the talk of [Dr. Markus Tischer (DESY)](https://photon-science.desy.de/research/technical_groups/undulators/group_members/index_eng.html) in the [ID23](https://aps.anl.gov/Magnetic-Devices/Workshops-Proceedings/ID-23) workshop.

### Magnet

The magnetic configuration can be selected in the pop down list. Users can tune the parameters from the default values in either ($a, b, c$) or ($B_r, M, h$) configuration. APPLE-II is based on the $B_r = 0.62$ expirically. The magnetic field can be approximated in the following equations;

$$B_0 = a \cdot \exp \left({g \over \lambda_u} \left( b + {g \over \lambda_u}c \right) \right)$$ 

by [K. Halbach, J. Phys. Colloques 44, C1-211-C1-216 (1983)](https://doi.org/10.1051/jphyscol:1983120), and 

$$B_0 = 2 B_r {\sin(\pi/M) \over (\pi/M)} \left( 1 - e^{-2 \pi h/\lambda_u} \right) e^{-\pi g/\lambda_u}$$ 

by [K. Halbach, Nucl. Instrum. Methods 187, 109 (1981)](https://doi.org/10.1016/0029-554X(81)90477-8). $M$ represents the number of magnets in a priod, and $h$ the height of magnet. The `effective magnetic field` or `K` depends on the vender specifications or the field measurements in magnet arrays on-site.


### Preset

Users can import and export the parameters as a preset (.dat) in Python version.


### Non-linear effects

No emittance or energy spread are taken into account resulting in the single electron and Gaussian beam approximation. Further optimization including the end-magnet, phase error, and beta function should be conducted in [SPECTRA](https://spectrax.org/spectra/) or [SRW](https://www.aps.anl.gov/Science/Scientific-Software/OASYS). The theoretical background and formula are summarized by [Takashi Tanaka](https://doi.org/10.1103/PhysRevAccelBeams.21.110704) and [Jui-Che Huang](https://doi.org/10.1103/PhysRevAccelBeams.20.064801).


### Limitations

No warranty of **U4Opt** without errors. Python and Igor Pro work in the same manner, but Igor Pro runs faster than Python does. The data can be handled in Igor as a wave within the program and transformed in further analysis.


## Setup

### Python (tested in Windows and macOS)

Install [Python3](https://www.python.org/) and [pip3](https://pip.pypa.io/en/stable/installation/) install numpy, scipy, PyQt5, matplotlib, and reliability. 

```
pip3 install numpy
pip3 install scipy
pip3 install pyqt5
pip3 install matplotlib
pip3 install reliability
```

Download this repository and run the main.py under the Python folder.
```
python3 main.py
```

### [Igor Pro](https://www.wavemetrics.com/) version 8 or 9 (tested in Windows and macOS)

Open the procedure file, then compile it. Undulator is available in the macro menu. Select the plot in the popup menu of **U4Opt** interface.

#### MPW and BM radiations

The flux of multi-pole wiggler (MPW) and bending magnet (BM) radiation can be added in Igor version. The flux of MPW is limited at the horizontal acceptance angle of 1 mrad. The magnet type and periodic length of MPW are equivalent to those used in the undulator. The magnetic field of BM is evaluated from the beam energy because the circumarence is roughly proportional to the beam energy ([Lightsources2018.csv](/LS/Lightsources2018.csv)). The on-axis angular flux density of BM is caluclated in 

$${\partial F \over \partial (\Delta \omega/\omega)}= 1.33 \cdot 10^{13} E^2 I \left( {\omega \over \omega_c} \right)^2 K^2_{2/3} \left( {\omega \over 2 \omega_c} \right)$$

and MPW generates its $2N$ times [https://www.cockcroft.ac.uk/wp-content/uploads/2014/12/Lecture-1.pdf](https://www.cockcroft.ac.uk/wp-content/uploads/2014/12/Lecture-1.pdf).

## Usage

* Setup the basic parameters like the energy, current, length, and harmonic number.
* Choose the magnet type like PPM, hybrid, cryogenic, superconducting, and APPLE-II.
* Setup the plot ranges like the period, K, gap, flux, and energy.
* Adjust the period at the maximum K (minimum gap) in the variable or slider.


## References

### Basic principles

- [The properties of undulator radiation, M.R. Howells and B.M. Kincaid (1993).](https://cds.cern.ch/record/260372/files/P00021955.pdf)

- [Insertion devices: undulators and wigglers, Richard P. Walker (1997).](https://indico.ictp.it/event/a02011/contribution/1)

- [The Science and Technology of Undulators and Wigglers, James A. Clarke (2004).](https://doi.org/10.1093/acprof:oso/9780198508557.001.0001)

- [Insertion devices, Johannes Bahrdt (2006).](http://dx.doi.org/10.5170/CERN-2006-002.441)



### Magnet parameters

- [Design considerations for a 1Å SASE undulator, P. Elleaume, J. Chavanne, Bart Faatz, Nucl. Instrum. Methods Phys. Res. A 455, 503 (2000).](https://doi.org/10.1016/S0168-9002(00)00544-1)

- [Short-Period APPLE II Undulator for Generating 12-15 keV X-Rays at the Advanced Photon Source, R. Dejus and S. Sasaki, ANL/APS/LS-313 rev. 3 (2009).](https://www.aps.anl.gov/files/APS-sync/lsnotes/files/APS_1418272.pdf)

## Interface

### Python (adjustable period shown as a pink marker)

![Python_u4opt.PNG](/Images/Python_u4opt.PNG)

### Igor Pro (2D plot can be either contour or image, not only energy but also flux, etc.)

![IgorPro_undulator.PNG](/Images/IgorPro_undulator_interface.PNG)

### Igor Pro (adjustable period shown as a cross hair)

![IgorPro_undulator.PNG](/Images/IgorPro_undulator1.PNG)


