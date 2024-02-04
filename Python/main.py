# U4Opt: U4opt for the undulator optimization, Copyright (C) 2024, Hideki NAKAJIMA, Synchrotron Light Research Institute, Thailand

from PyQt5.QtCore import Qt, QDir
from PyQt5.QtWidgets import QMainWindow, QGridLayout, QWidget, QComboBox, QApplication, QLineEdit, QLabel, QSlider, QSpinBox, QDoubleSpinBox, QFileDialog
import sys, os, ast
import numpy as np
from scipy.special import jv
import matplotlib.pyplot as plt
from matplotlib import style
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt5agg import NavigationToolbar2QT as NavigationToolbar
from reliability.Other_functions import crosshairs

import faulthandler

#style.use('fast')
#style.use('seaborn-pastel')
faulthandler.enable()

class PrettyWidget(QMainWindow):
    def __init__(self):
        super(PrettyWidget, self).__init__()
        self.initUI()

    def initUI(self):
        version = 'U4Opt: Undulator to be optimized ver. 0.006'
        #self.floating = '.2f'

        # Home directory
        self.filePath = QDir.homePath()
        #self.filePath = '/Users/hidekinakajima/Desktop/'

        # window size can be adjustable in window_scale factor, default: 1
        window_scale = 1
        self.setGeometry(300, 600, int(1000 * window_scale), int(800 * window_scale))
        # grid withd and height
        min_width = 40
        max_width = 80
        fix_height = 20
        fix_width = 10

        self.setWindowTitle(version)
        self.statusBar().showMessage('Copyright (C) 2024, Hideki NAKAJIMA, Synchrotron Light Research Institute, Nakhon Ratchasima, Thailand')

        # Grid Layout
        grid = QGridLayout()
        widget = QWidget(self)
        self.setCentralWidget(widget)
        widget.setLayout(grid)

        # Figure: Canvas and Toolbar
        figure = plt.figure(figsize=(8,3))
        gs = figure.add_gridspec(1, 2)
        self.ax1 = figure.add_subplot(gs[0, 0])
        self.ax2 = figure.add_subplot(gs[0, 1])
        plt.subplots_adjust(left=None, bottom=None, right=None, top=None, wspace=0.5, hspace=None)

        self.canvas = FigureCanvas(figure)
        toolbar = NavigationToolbar(self.canvas, self)
        toolbar.setFixedHeight(fix_height)
        toolbar.setFixedWidth(600)
        toolbar.setStyleSheet("QToolBar { border: 0px }")
        grid.addWidget(self.canvas, 7,0,2,15)
        #grid.addWidget(toolbar, 6,0,1,8)
        grid.addWidget(toolbar, 0,6,1,8)
        # DropDown machine list
        self.list_preset = ['Machine parameters','SPS-II U20', 'Nano Terasu U22', 'KEK PF U16', 'SPring-8 U32', 'MAX-IV DanMAX', 'Load preset', 'Save preset']
        self.comboBox_preset = QComboBox(self)
        self.comboBox_preset.addItems(self.list_preset)
        grid.addWidget(self.comboBox_preset, 0, 0, 1, 2)
        self.comboBox_preset.currentIndexChanged.connect(self.preset)
        self.comboBox_preset.setCurrentIndex(0)

        # default machine parameter
        self.variables = [3,0.3,2,7,0,2.076,-3.24,0,1.38,4,0.5,15,22,71,1,3,21,4,5.5,4,13,16,1,20,20,2.03]
        # default magnet parameters
        # https://doi.org/10.1016/S0168-9002(00)00544-1
        self.default_magnet = [[2.076, -3.24, 0],[3.694, -5.068, 1.52],[4.625, -5.251, 2.079],[12.42, -4.79, 0.385],[1.38,4,0.50],[0.62,4,0.50]]
        self.reloaded = 0

        label_energy = QLabel('Energy (GeV):')
        label_energy.setMinimumWidth(min_width)
        label_energy.setMaximumWidth(max_width)
        grid.addWidget(label_energy, 1, 0)
        self.beam_energy = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.variables[0], singleStep=1)
        self.beam_energy.editingFinished.connect(self.update_beam_energy)
        self.beam_energy.setMinimumWidth(min_width)
        self.beam_energy.setMaximumWidth(max_width)
        grid.addWidget(self.beam_energy, 1, 1)

        grid.addWidget(QLabel('Current (A):'), 2, 0)
        self.beam_current = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.variables[1], singleStep=0.1)
        self.beam_current.editingFinished.connect(self.update_beam_current)
        grid.addWidget(self.beam_current, 2, 1)

        grid.addWidget(QLabel('Length (m):'), 3, 0)
        self.undulator_length = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.variables[2], singleStep=1)
        self.undulator_length.editingFinished.connect(self.update_undulator_length)
        grid.addWidget(self.undulator_length, 3, 1)

        grid.addWidget(QLabel('Harmonic (odd):'), 4, 0)
        self.harmonic_number = QSpinBox(minimum=1, maximum=1001, value=self.variables[3], singleStep=2)
        self.harmonic_number.editingFinished.connect(self.update_harmonic_number)
        grid.addWidget(self.harmonic_number, 4, 1)

        # blank column
        blank_column2 = QLabel('')
        grid.addWidget(blank_column2, 0, 2)
        blank_column2.setFixedWidth(fix_width)

        # magnetic field calculation
        grid.addWidget(QLabel('Magnetic field simulation'), 0, 3, 1, 4)

        # DropDown magnets list
        self.list_magnet = ['Pure Permanent Magnet (a,b,c)', 'Hybrid permendur pole (a,b,c)', 'Cryogenic permanent magnet (a,b,c)', 'Superconducting magnet (a,b,c)', 'PPM based on (Br,M,hM)', 'APPLE-II [n=1, Kx=Ky] (Br,M,hM)']
        self.comboBox_magnet = QComboBox(self)
        self.comboBox_magnet.addItems(self.list_magnet)
        grid.addWidget(self.comboBox_magnet, 1, 3, 1, 4)
        self.comboBox_magnet.currentIndexChanged.connect(self.magnet)
        self.comboBox_magnet.setCurrentIndex(0)

        label_a = QLabel('coef. a:')
        label_a.setMinimumWidth(min_width)
        label_a.setMaximumWidth(max_width)
        grid.addWidget(label_a, 2, 3)
        self.variable_a = QDoubleSpinBox(minimum=-10, maximum=10, value=self.variables[5], singleStep=0.1)
        self.variable_a.editingFinished.connect(self.update_variable_a)
        self.variable_a.setMinimumWidth(min_width)
        self.variable_a.setMaximumWidth(max_width)
        grid.addWidget(self.variable_a, 2, 4)

        grid.addWidget(QLabel('coef. b:'), 3, 3)
        self.variable_b = QDoubleSpinBox(minimum=-10, maximum=10, value=self.variables[6], singleStep=0.1)
        self.variable_b.editingFinished.connect(self.update_variable_b)
        grid.addWidget(self.variable_b, 3, 4)

        grid.addWidget(QLabel('coef. c:'), 4, 3)
        self.variable_c = QDoubleSpinBox(minimum=-10, maximum=10, value=self.variables[7], singleStep=0.1)
        self.variable_c.editingFinished.connect(self.update_variable_c)
        grid.addWidget(self.variable_c, 4, 4)

        # PPM only
        label_Br = QLabel('Br (T):')
        label_Br.setMinimumWidth(min_width)
        label_Br.setMaximumWidth(max_width)
        grid.addWidget(label_Br, 2, 5)
        self.variable_Br = QDoubleSpinBox(minimum=0.01, maximum=20, value=self.variables[8], singleStep=0.1)
        self.variable_Br.editingFinished.connect(self.update_variable_Br)
        self.variable_Br.setMinimumWidth(min_width)
        self.variable_Br.setMaximumWidth(max_width)
        grid.addWidget(self.variable_Br, 2, 6)

        grid.addWidget(QLabel('M:'), 3, 5)
        self.variable_M = QSpinBox(minimum=1, maximum=10, value=self.variables[9], singleStep=1)
        self.variable_M.editingFinished.connect(self.update_variable_M)
        grid.addWidget(self.variable_M, 3, 6)

        grid.addWidget(QLabel('hM/per.:'), 4, 5)
        self.variable_h = QDoubleSpinBox(minimum=0.01, maximum=10, value=self.variables[10], singleStep=0.1)
        self.variable_h.editingFinished.connect(self.update_variable_h)
        grid.addWidget(self.variable_h, 4, 6)

        # blank column
        blank_column7 = QLabel('')
        grid.addWidget(blank_column7, 0, 7)
        blank_column7.setFixedWidth(fix_width)

        # plot setting
        grid.addWidget(QLabel('Plot range'), 1, 8, 1, 1)

        label_period = QLabel('Period (mm)')
        label_period.setMinimumWidth(min_width)
        label_period.setMaximumWidth(max_width)
        grid.addWidget(label_period, 1, 9)

        label_initial = QLabel('Initial:')
        label_initial.setMinimumWidth(min_width)
        label_initial.setMaximumWidth(max_width)
        grid.addWidget(label_initial, 2, 8)
        self.period_initial = QDoubleSpinBox(minimum=1, maximum=1000, value=self.variables[11], singleStep=1)
        self.period_initial.editingFinished.connect(self.update_period_initial)
        grid.addWidget(self.period_initial, 2, 9)

        grid.addWidget(QLabel('End:'), 3, 8)
        self.period_end = QDoubleSpinBox(minimum=1, maximum=1000, value=self.variables[12], singleStep=1)
        self.period_end.editingFinished.connect(self.update_period_end)
        grid.addWidget(self.period_end, 3, 9)

        grid.addWidget(QLabel('Points:'), 4, 8)
        self.period_points = QSpinBox(minimum=2, maximum=1001, value=self.variables[13], singleStep=10)
        self.period_points.editingFinished.connect(self.update_period_points)
        grid.addWidget(self.period_points, 4, 9)

        label_K = QLabel('K')
        label_K.setMinimumWidth(min_width)
        label_K.setMaximumWidth(max_width)
        grid.addWidget(label_K, 1, 10)
        self.K_initial = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.variables[14], singleStep=1)
        self.K_initial.editingFinished.connect(self.update_K_initial)
        grid.addWidget(self.K_initial, 2, 10)

        self.K_end = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.variables[15], singleStep=1)
        self.K_end.editingFinished.connect(self.update_K_end)
        grid.addWidget(self.K_end, 3, 10)

        self.K_points = QSpinBox(minimum=2, maximum=1001, value=self.variables[16], singleStep=10)
        self.K_points.editingFinished.connect(self.update_K_points)
        grid.addWidget(self.K_points, 4, 10)

        label_gap = QLabel('Gap (mm)')
        label_gap.setMinimumWidth(min_width)
        label_gap.setMaximumWidth(max_width)
        grid.addWidget(label_gap, 1, 11)
        self.gap_initial = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.variables[17], singleStep=1)
        self.gap_initial.editingFinished.connect(self.update_gap_initial)
        grid.addWidget(self.gap_initial, 2, 11)

        self.gap_end = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.variables[18], singleStep=1)
        self.gap_end.editingFinished.connect(self.update_gap_end)
        grid.addWidget(self.gap_end, 3, 11)

        self.gap_points = QSpinBox(minimum=2, maximum=1001, value=self.variables[19], singleStep=1)
        self.gap_points.editingFinished.connect(self.update_gap_points)
        grid.addWidget(self.gap_points, 4, 11)

        label_flux = QLabel('Flux (b)')
        label_flux.setMinimumWidth(min_width)
        label_flux.setMaximumWidth(max_width)
        grid.addWidget(label_flux, 1, 12)
        self.flux_initial = QSpinBox(minimum=1, maximum=22, value=self.variables[20], singleStep=1)
        self.flux_initial.editingFinished.connect(self.update_flux_initial)
        grid.addWidget(self.flux_initial, 2, 12)

        self.flux_end = QSpinBox(minimum=1, maximum=22, value=self.variables[21], singleStep=1)
        self.flux_end.editingFinished.connect(self.update_flux_end)
        grid.addWidget(self.flux_end, 3, 12)

        label_photon_energy = QLabel('Energy (keV)')
        label_photon_energy.setMinimumWidth(min_width)
        label_photon_energy.setMaximumWidth(max_width)
        grid.addWidget(label_photon_energy, 1, 13)
        self.energy_initial = QDoubleSpinBox(minimum=0.01, maximum=100, value=self.variables[22], singleStep=1)
        self.energy_initial.editingFinished.connect(self.update_energy_initial)
        grid.addWidget(self.energy_initial, 2, 13)

        self.energy_end = QDoubleSpinBox(minimum=0.01, maximum=100, value=self.variables[23], singleStep=1)
        self.energy_end.editingFinished.connect(self.update_energy_end)
        grid.addWidget(self.energy_end, 3, 13)

        # blank column (adjustable for plot)
        blank_column14 = QLabel('')
        grid.addWidget(blank_column14, 0, 14)

        # blank line
        blank_space = QLabel('')
        grid.addWidget(blank_space, 5, 0)
        blank_space.setFixedHeight(fix_height/2)

        # Slider to optimize the period and K
        #self.lu_t = 20
        #self.K_t = 2.03
        # adjustable lu and K in flux
        label_adj_per = QLabel('Adj. per. (mm):')
        label_adj_per.setFixedHeight(fix_height)
        grid.addWidget(label_adj_per, 6, 8)
        self.target_period = QDoubleSpinBox(minimum=1, maximum=1000, value=self.variables[24], singleStep=0.5)
        self.target_period.valueChanged.connect(self.calc_target_K)
        grid.addWidget(self.target_period, 6, 9)

        self.slider_target_period = QSlider(Qt.Orientation.Horizontal)
        self.slider_target_period.setRange(1,100)
        self.slider_target_period.setSingleStep(1)
        self.slider_target_period.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.slider_target_period.setValue(self.variables[24])
        self.slider_target_period.valueChanged.connect(self.target_period.setValue)
        grid.addWidget(self.slider_target_period, 6, 10, 1, 2)

        grid.addWidget(QLabel('max K:'), 6, 12)
        self.target_K = QDoubleSpinBox(minimum=0.01, maximum=100, value=self.variables[25], singleStep=0.5)
        self.target_K.editingFinished.connect(self.calc_target_K_t)
        grid.addWidget(self.target_K, 6, 13)
        """
        self.slider_target_K = QSlider(Qt.Orientation.Horizontal)
        self.slider_target_K.setRange(0.1,10)
        self.slider_target_K.setSingleStep(1)
        self.slider_target_K.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.slider_target_K.setTickInterval(1)
        self.slider_target_K.setValue(self.K_t)
        self.slider_target_K.editingFinished.connect(self.target_K.setValue)
        grid.addWidget(self.slider_target_K, 7, 10, 1, 2)
        """
        self.calc()
        self.show()

    def calc_target_K(self):
        self.variables[24] = self.target_period.value()
        if self.comboBox_magnet.currentIndex() < 4:
            self.variables[25] = 0.0934*self.variables[24]*self.variables[5]*np.exp((self.variables[17]/self.variables[24])*(self.variables[6]+self.variables[7]*(self.variables[17]/self.variables[24])))
        elif self.comboBox_magnet.currentIndex() >= 4:
            self.variables[25] = 0.0934*self.variables[24]*2*self.variables[8]*(np.sin(np.pi/self.variables[9])/(np.pi/self.variables[9]))*np.exp(-np.pi*(self.variables[17]/self.variables[24]))*(1-np.exp(-2*np.pi*self.variables[10]))

        self.target_K.setValue(self.variables[25])
        self.slider_target_period.setValue(self.variables[24])
        #self.slider_target_K.setValue(self.K_t)
        self.calc()

    def calc_target_K_t(self):
        self.variables[25] = self.target_K.value()
        #self.slider_target_K.setValue(self.K_t)
        self.calc()

    def update_beam_energy(self):
        self.variables[0] = self.beam_energy.value()
        self.calc()

    def update_beam_current(self):
        self.variables[1] = self.beam_current.value()
        self.calc()

    def update_undulator_length(self):
        self.variables[2] = self.undulator_length.value()
        self.calc()

    def update_harmonic_number(self):
        self.variables[3] = self.harmonic_number.value()
        self.calc()

    # self.variables [4] for index of magnet type

    def update_variable_a(self):
        self.variables[5] = self.variable_a.value()
        self.calc()

    def update_variable_b(self):
        self.variables[6] = self.variable_b.value()
        self.calc()

    def update_variable_c(self):
        self.variables[7] = self.variable_c.value()
        self.calc()

    def update_variable_Br(self):
        self.variables[8] = self.variable_Br.value()
        self.calc()

    def update_variable_M(self):
        self.variables[9] = self.variable_M.value()
        self.calc()

    def update_variable_h(self):
        self.variables[10] = self.variable_h.value()
        self.calc()

    def update_period_initial(self):
        self.variables[11] = self.period_initial.value()
        self.calc()

    def update_period_end(self):
        self.variables[12] = self.period_end.value()
        self.calc()

    def update_period_points(self):
        self.variables[13] = self.period_points.value()
        self.calc()

    def update_K_initial(self):
        self.variables[14] = self.K_initial.value()
        self.calc()

    def update_K_end(self):
        self.variables[15] = self.K_end.value()
        self.calc()

    def update_K_points(self):
        self.variables[16] = self.K_points.value()
        self.calc()

    def update_gap_initial(self):
        self.variables[17] = self.gap_initial.value()
        self.calc()

    def update_gap_end(self):
        self.variables[18] = self.gap_end.value()
        self.calc()

    def update_gap_points(self):
        self.variables[19] = self.gap_points.value()
        self.calc()

    def update_flux_initial(self):
        self.variables[20] = self.flux_initial.value()
        self.calc()

    def update_flux_end(self):
        self.variables[21] = self.flux_end.value()
        self.calc()

    def update_energy_initial(self):
        self.variables[22] = self.energy_initial.value()
        self.calc()

    def update_energy_end(self):
        self.variables[23] = self.energy_end.value()
        self.calc()

    def calc(self):
        hc = 1.23498*10**-6
        gamma = self.variables[0]/0.000511
        K0 = 0.01

        if self.comboBox_magnet.currentIndex() == 5:
            self.variables[3] = 1
            self.harmonic_number.setValue(self.variables[3])

        n_pnt = int((self.variables[3]+1)/2)
        lu = np.linspace(self.variables[11], self.variables[12], self.variables[13])
        K = np.linspace(self.variables[14], self.variables[15], self.variables[16])
        gap = np.linspace(self.variables[17], self.variables[18], self.variables[19])
        n = np.linspace(1, self.variables[3], n_pnt)
        Kf = np.linspace(K0, self.variables[25], self.variables[16])

        x1, y1 = np.meshgrid(lu, K)
        x2, y2 = np.meshgrid(lu, gap)
        x3, y3 = np.meshgrid(Kf, n)

        if self.comboBox_magnet.currentIndex() < 4:
            # Planar
            K_lu = hc*10**-3/(x1*10**-3*(1+y1**2/2)/(2*gamma**2)/self.variables[3])
            Np = np.floor(self.variables[2]/self.variables[24]*1000)
            Y = y3*(x3**2)/(4*(1+x3**2/2))
            Qk = (y3/(1+x3**2/2))*(x3**2*(jv((y3-1)/2,Y)-jv((y3+1)/2,Y))**2)
            fx = 1.431*10**14*Np*Qk*self.variables[1]
            en = hc*10**-3/((self.variables[24]*10**-3/(2*gamma**2))*(1+x3**2/2)/y3)
        elif self.comboBox_magnet.currentIndex() >= 4:
            # helical n=1, Kx=Ky (Br = 0.62 T based on APS report)
            # https://www.aps.anl.gov/files/APS-sync/lsnotes/files/APS_1418272.pdf
            K_lu = hc*10**-3/(x1*10**-3*(1+y1**2)/(2*gamma**2))
            Np = np.floor(self.variables[2]/self.variables[24]*1000)
            Y = 0
            Qk = x3**2/(1+x3**2)
            fx = 2.862*10**14*Np*Qk*self.variables[1]
            en = hc*10**-3/((self.variables[24]*10**-3/(2*gamma**2))*(1+x3**2))

        if self.comboBox_magnet.currentIndex() < 4:
            g = 0.0934*x2*self.variables[5]*np.exp((y2/x2)*(self.variables[6]+self.variables[7]*(y2/x2)))
        elif self.comboBox_magnet.currentIndex() >= 4:
            g = 0.0934*x2*2*self.variables[8]*(np.sin(np.pi/self.variables[9])/(np.pi/self.variables[9]))*np.exp(-np.pi*(y2/x2))*(1-np.exp(-2*np.pi*self.variables[10]))

        self.ax1.cla()
        self.ax2.cla()

        self.ax1.set_title('Photon energy (keV)')
        self.ax2.set_title('Flux vs energy')

        # coordinate in z
        Xflat, Yflat, Zflat = x1.flatten(), y1.flatten(), K_lu.flatten()
        def fmt(x, y):
            # get closest point with known data
            dist = np.linalg.norm(np.vstack([Xflat - x, Yflat - y]), axis=0)
            idx = np.argmin(dist)
            z = Zflat[idx]
            return 'x={x:.2f} y={y:.2f} z={z:.2f}'.format(x=x, y=y, z=z)
        self.ax1.format_coord = fmt

        # plot contour for photon energy (keV)
        cntr = self.ax1.contour(x1, y1, K_lu, 20, cmap='viridis')
        # https://matplotlib.org/stable/users/explain/colors/colormaps.html
        self.ax1.clabel(cntr, fmt="%2.1f", use_clabeltext=True)

        # plot gap lines
        for i in range(self.variables[19]):
            self.ax1.plot(lu, g[i,:], lw=2, label=str(gap[i])+" mm")
            if i == 0:
                self.ax1.annotate(' Gap (mm)', xy=(self.variables[12], g[i,-1]+0.1))
            self.ax1.annotate(' ' +str("{0:.2f}".format(gap[i])), xy=(self.variables[12], g[i,-1]))

        self.ax1.set_xlim(self.variables[11], self.variables[12])
        self.ax1.set_ylim(self.variables[14], self.variables[15])

        self.ax1.grid()
        self.ax1.set_xlabel("Period (mm)")
        self.ax1.set_ylabel("K")
        # plot flux vs energy
        for i in range(n_pnt):
            self.ax2.loglog(en[i,:], fx[i,:], lw=2, label="har. "+str(int(n[i])))
            self.ax2.annotate(str(int(n[i])), xy=(en[i,-1], fx[i,-1]))

        if self.comboBox_magnet.currentIndex() < 4:
            self.variables[25] = 0.0934*self.variables[24]*self.variables[5]*np.exp((self.variables[17]/self.variables[24])*(self.variables[6]+self.variables[7]*(self.variables[17]/self.variables[24])))
        elif self.comboBox_magnet.currentIndex() >= 4:
            self.variables[25] = 0.0934*self.variables[24]*2*self.variables[8]*(np.sin(np.pi/self.variables[9])/(np.pi/self.variables[9]))*np.exp(-np.pi*(self.variables[17]/self.variables[24]))*(1-np.exp(-2*np.pi*self.variables[10]))

        self.target_K.setValue(self.variables[25])

        self.ax1.plot(self.variables[24], self.variables[25], marker = 'o', ms = 10, mec = 'hotpink', mfc = 'hotpink', label='target')
        #self.ax1.annotate('target', xy=(self.lu_t, self.K_t))

        crosshairs(xlabel='x',ylabel='y',decimals=2)

        self.ax2.format_coord = lambda x, y: f"x={x:.2f} y={y:.2e}"
        self.ax2.set_xlim([self.variables[22], self.variables[23]])
        self.ax2.set_ylim([10**self.variables[20], 10**self.variables[21]])

        self.ax2.get_xaxis().get_major_formatter().labelOnlyBase = False
        #self.ax2.set_xticks([0.5,0.6,0.7,0.8,0.9,1,2,3,4,5,6,7,8,9,10,20,30,40,50])
        #self.ax2.set_xticks([1,2,3,4,5,6,7,8,9,10])

        self.ax2.set_xlabel("Energy (keV)")
        self.ax2.set_ylabel("Flux (ph/s/0.1%bw)")
        self.ax2.grid(which='minor', alpha=0.3)
        self.ax2.grid(which='major', alpha=1)

        self.canvas.draw()
        #self.repaint()

    def preset(self):
        self.reloaded == 0
        if self.comboBox_preset.currentIndex() == 0:
            pass  #print('Enjoy!')
            #self.variables = [3,0.3,2,7,0,2.076,-3.24,0,1.38,4,0.5,15,22,71,1,3,21,4,5.5,4,13,16,1,20,20,2.03]
            #self.set_preset()
        elif self.comboBox_preset.currentIndex() == 1:
            # SPS_II
            self.variables = [3,0.3,2,7,1,3.69,-5.07,1.52,1.38,4,0.5,15,22,71,1,3,21,4,5.5,4,13,16,1,20,20,2.66]
            self.set_preset()
        elif self.comboBox_preset.currentIndex() == 2:
            # Nano Terasu
            self.variables = [3,0.3,2,7,0,2.076,-3.24,0,1.38,4,0.5,17,24,71,1,3,21,4,5.5,4,13,16,1,20,22,2.37]
            self.set_preset()
        elif self.comboBox_preset.currentIndex() == 3:
            # KEK PF
            self.variables = [2.6,0.3,2,7,0,2.076,-3.24,0,1.38,4,0.5,12,20,81,0.5,2.5,21,4,5.5,4,13,16,1,20,16,1.38]
            self.set_preset()
        elif self.comboBox_preset.currentIndex() == 4:
            # SPring-8
            self.variables = [8,0.3,2,7,0,2.076,-3.24,0,1.38,4,0.5,28,35,71,3,5,21,4,5.5,4,13,16,1,100,32,4.15]
            self.set_preset()
        elif self.comboBox_preset.currentIndex() == 5:
            # MAX-IV
            self.variables = [3,0.3,2,7,1,3.69,-5.07,1.52,1.38,4,0.5,15,22,71,1,3,21,4,5.5,4,13,16,1,20,16,1.71]
            self.set_preset()
        elif self.comboBox_preset.currentIndex() == 6:
            # load Preset
            self.load_preset(0)
        elif self.comboBox_preset.currentIndex() == 7:
            # save Preset
            self.save_preset()
        elif self.comboBox_preset.currentIndex() > 7:
            # reload addended presets
            self.load_preset(self.comboBox_preset.currentIndex())
            if self.reloaded == 1:
                self.set_preset()

    def load_preset(self, reload):
        if reload > 0:
            cfilePath = str(self.comboBox_preset.currentText())
        else:
            cfilePath, _ = QFileDialog.getOpenFileName(self, 'Open data file', self.filePath, "DAT Files (*.dat)")

        if cfilePath != "":
            #print (cfilePath)
            self.filePath = cfilePath
            with open(cfilePath, 'r') as file:
                self.variables = file.read()
            file.close

            self.variables = ast.literal_eval(self.variables)

            #fileName = os.path.basename(str(cfilePath))
            #fileName = os.path.splitext(fileName)[0]
            if reload == 0:
                self.list_preset.append(str(cfilePath))
                self.comboBox_preset.clear()
                self.comboBox_preset.addItems(self.list_preset)
                self.comboBox_preset.setCurrentIndex(len(self.list_preset)-1)
            else:
                self.comboBox_preset.setCurrentIndex(reload)
                self.reloaded = 1 # need to be set_preset
        else:
            self.comboBox_preset.setCurrentIndex(0)

    def save_preset(self):
        cfilePath = self.filePath
        fileName = 'SR_U'

        # S_File will get the directory path and extension.
        cfilePath,_ = QFileDialog.getSaveFileName(self, 'Save Preset file', cfilePath+os.sep+fileName+'.dat', "DAT Files (*.dat)")

        if cfilePath != "":
            self.filePath = cfilePath
            # Finally this will Save your file to the path selected.
            with open(cfilePath, 'w') as file:
                file.write(str(self.variables))
            file.close

            self.list_preset.append(str(cfilePath))
            self.comboBox_preset.clear()
            self.comboBox_preset.addItems(self.list_preset)
            self.comboBox_preset.setCurrentIndex(len(self.list_preset)-1)
        else:
            self.comboBox_preset.setCurrentIndex(0)

    def set_preset(self):
        #print(str(self.reloaded) + ", "+  str(self.variables[8]))
        self.beam_energy.setValue(self.variables[0])
        self.beam_current.setValue(self.variables[1])
        self.undulator_length.setValue(self.variables[2])
        self.harmonic_number.setValue(self.variables[3])
        self.comboBox_magnet.setCurrentIndex(self.variables[4])
        self.variable_a.setValue(self.variables[5])
        self.variable_b.setValue(self.variables[6])
        self.variable_c.setValue(self.variables[7])
        self.variable_Br.setValue(self.variables[8])
        self.variable_M.setValue(self.variables[9])
        self.variable_h.setValue(self.variables[10])
        self.period_initial.setValue(self.variables[11])
        self.period_end.setValue(self.variables[12])
        self.period_points.setValue(self.variables[13])
        self.K_initial.setValue(self.variables[14])
        self.K_end.setValue(self.variables[15])
        self.K_points.setValue(self.variables[16])
        self.gap_initial.setValue(self.variables[17])
        self.gap_end.setValue(self.variables[18])
        self.gap_points.setValue(self.variables[19])
        self.flux_initial.setValue(self.variables[20])
        self.flux_end.setValue(self.variables[21])
        self.energy_initial.setValue(self.variables[22])
        self.energy_end.setValue(self.variables[23])
        self.target_period.setValue(self.variables[24])
        self.target_K.setValue(self.variables[25])
        self.calc()

    def magnet(self):
        if self.reloaded == 0:
            if self.comboBox_magnet.currentIndex() == 0:
                self.variables[4] = 0
                self.variable_a.setValue(self.default_magnet[0][0])
                self.variable_b.setValue(self.default_magnet[0][1])
                self.variable_c.setValue(self.default_magnet[0][2])
            elif self.comboBox_magnet.currentIndex() == 1:
                self.variables[4] = 1
                self.variable_a.setValue(self.default_magnet[1][0])
                self.variable_b.setValue(self.default_magnet[1][1])
                self.variable_c.setValue(self.default_magnet[1][2])
            elif self.comboBox_magnet.currentIndex() == 2:
                self.variables[4] = 2
                self.variable_a.setValue(self.default_magnet[2][0])
                self.variable_b.setValue(self.default_magnet[2][1])
                self.variable_c.setValue(self.default_magnet[2][2])
            elif self.comboBox_magnet.currentIndex() == 3:
                self.variables[4] = 3
                self.variable_a.setValue(self.default_magnet[3][0])
                self.variable_b.setValue(self.default_magnet[3][1])
                self.variable_c.setValue(self.default_magnet[3][2])
            elif self.comboBox_magnet.currentIndex() == 4:
                self.variables[4] = 4
                self.variable_Br.setValue(self.default_magnet[4][0])
                self.variable_M.setValue(self.default_magnet[4][1])
                self.variable_h.setValue(self.default_magnet[4][2])
            elif self.comboBox_magnet.currentIndex() == 5:
                self.variables[4] = 5
                self.variable_Br.setValue(self.default_magnet[5][0])
                self.variable_M.setValue(self.default_magnet[5][1])
                self.variable_h.setValue(self.default_magnet[5][2])

            if self.comboBox_magnet.currentIndex() < 4:
                self.variables[5] = self.variable_a.value()
                self.variables[6] = self.variable_b.value()
                self.variables[7] = self.variable_c.value()
            elif self.comboBox_magnet.currentIndex() >= 4:
                self.variables[8] = self.variable_Br.value()
                self.variables[9] = self.variable_M.value()
                self.variables[10] = self.variable_h.value()

            # calc K_t based on the period
            if self.comboBox_magnet.currentIndex() < 4:
                self.variables[25] = 0.0934*self.variables[24]*self.variables[5]*np.exp((self.variables[17]/self.variables[24])*(self.variables[6]+self.variables[7]*(self.variables[17]/self.variables[24])))
            elif self.comboBox_magnet.currentIndex() >= 4:
                self.variables[25] = 0.0934*self.variables[24]*2*self.variables[8]*(np.sin(np.pi/self.variables[9])/(np.pi/self.variables[9]))*np.exp(-np.pi*(self.variables[17]/self.variables[24]))*(1-np.exp(-2*np.pi*self.variables[10]))

            self.target_K.setValue(self.variables[25])

            self.calc()
        else:
            # load preset (not default)
            self.reloaded = 0 # reset if load preset

    def closeEvent(self, event):
        event.accept()
        sys.exit(0)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    w = PrettyWidget()
    sys.exit(app.exec_())
