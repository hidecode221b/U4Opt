# U4Opt: U4opt for the undulator optimization, Copyright (C) 2024, Hideki NAKAJIMA, Synchrotron Light Research Institute, Thailand

from PyQt5 import QtWidgets,QtCore
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QLineEdit, QLabel, QSlider, QSpinBox, QDoubleSpinBox
import sys
import numpy as np
from scipy.special import jv
import matplotlib.pyplot as plt
#from matplotlib import style
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt5agg import NavigationToolbar2QT as NavigationToolbar
#from reliability.Other_functions import crosshairs

import faulthandler

#style.use('ggplot')
#style.use('seaborn-pastel')
faulthandler.enable()

class PrettyWidget(QtWidgets.QMainWindow):
    def __init__(self):
        super(PrettyWidget, self).__init__()
        #super(PrettyWidget, self).__init__()
        self.initUI()

    def initUI(self):
        self.version = 'U4Opt: GUI for the undulator optimization ver. 0.001'
        self.floating = '.2f'

        # window size can be adjustable in window_scale factor, default: 1
        window_scale = 1
        # default window width 1400, height 800
        self.setGeometry(300, 600, int(1000 * window_scale), int(800 * window_scale))
        
        self.center()
        self.setWindowTitle(self.version)     
        self.statusBar().showMessage('Copyright (C) 2024, Hideki NAKAJIMA, Synchrotron Light Research Institute, Nakhon Ratchasima, Thailand')
        
        # Grid Layout 
        grid = QtWidgets.QGridLayout()
        widget = QtWidgets.QWidget(self)
        self.setCentralWidget(widget)
        widget.setLayout(grid)
        
        # Figure: Canvas and Toolbar
        self.figure = plt.figure(figsize=(10,6))
        gs = self.figure.add_gridspec(1, 2)
        self.ax1 = self.figure.add_subplot(gs[0, 0])
        self.ax2 = self.figure.add_subplot(gs[0, 1])
        plt.subplots_adjust(left=None, bottom=None, right=None, top=None, wspace=0.5, hspace=None)
        self.canvas = FigureCanvas(self.figure)
        self.toolbar = NavigationToolbar(self.canvas, self)
        self.toolbar.setFixedHeight(20)
        self.toolbar.setStyleSheet("QToolBar { border: 0px }")
        grid.addWidget(self.canvas, 7,0,2,15)
        grid.addWidget(self.toolbar, 6,0,1,15)
        
        machine_parameters = QLabel('Machine parameters')
        grid.addWidget(machine_parameters, 0, 0, 1, 2)
        machine_parameters.setFixedHeight(20)
        
        self.E_e = 3
        self.I_e = 0.3
        self.u_length = 2
        self.n_har = 7
        self.PPMU = [2.076, -3.24, 0]  # https://doi.org/10.1016/S0168-9002(00)00544-1
        self.HYBU = [3.694, -5.068, 1.52]
        self.CPMU = [4.625, -5.251, 2.079]
        self.SCMU = [12.42, -4.79, 0.385]
        self.a = 2.076
        self.b = -3.24
        self.c = 0
        self.Br = 1.38
        self.M = 4
        self.h = 0.5
        self.lu_0 = 15
        self.lu_1 = 22
        self.lu_pnt = 71
        self.K_0 = 1
        self.K_1 = 3
        self.K_pnt = 21
        self.gap_0 = 4
        self.gap_1 = 5.5
        self.gap_pnt = 4
        self.flux_0 = 13
        self.flux_1 = 16
        self.energy_0 = 1
        self.energy_1 = 30
        self.p = 2
        
        label_energy = QLabel('Energy (GeV):')
        label_energy.setFixedWidth(80)
        grid.addWidget(label_energy, 1, 0)
        self.beam_energy = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.E_e, singleStep=1)
        self.beam_energy.valueChanged.connect(self.update_beam_energy)
        self.beam_energy.setFixedWidth(80)
        grid.addWidget(self.beam_energy, 1, 1)
        
        grid.addWidget(QLabel('Current (A):'), 2, 0)
        self.beam_current = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.I_e, singleStep=0.1)
        self.beam_current.valueChanged.connect(self.update_beam_current)
        grid.addWidget(self.beam_current, 2, 1)
        
        grid.addWidget(QLabel('Length (m):'), 3, 0)
        self.undulator_length = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.u_length, singleStep=1)
        self.undulator_length.valueChanged.connect(self.update_undulator_length)
        grid.addWidget(self.undulator_length, 3, 1)
        
        grid.addWidget(QLabel('Harmonic (odd):'), 4, 0)
        self.harmonic_number = QSpinBox(minimum=1, maximum=1001, value=self.n_har, singleStep=2)
        self.harmonic_number.valueChanged.connect(self.update_harmonic_number)
        grid.addWidget(self.harmonic_number, 4, 1)
        
        # blank column
        blank_column2 = QLabel('')
        grid.addWidget(blank_column2, 0, 2)
        blank_column2.setFixedWidth(10)
        
        # magnetic field calculation
        grid.addWidget(QLabel('Magnetic field simulation'), 0, 3, 1, 2)
        
        # DropDown magnets list
        self.list_magnet = ['PPM (a,b,c)', 'Hybrid (a,b,c)', 'Cryogenic (a,b,c)', 'Superconducting (a,b,c)', 'PPM with (Br,M,h)']
        self.comboBox_magnet = QtWidgets.QComboBox(self)
        self.comboBox_magnet.addItems(self.list_magnet)
        grid.addWidget(self.comboBox_magnet, 1, 3, 1, 2)
        self.comboBox_magnet.currentIndexChanged.connect(self.magnet)
        self.comboBox_magnet.setCurrentIndex(0)
        
        label_a = QLabel('coef. a:')
        label_a.setFixedWidth(80)
        grid.addWidget(label_a, 2, 3)
        self.variable_a = QDoubleSpinBox(minimum=-10, maximum=10, value=self.a, singleStep=0.1)
        self.variable_a.valueChanged.connect(self.update_variable_a)
        self.variable_a.setFixedWidth(80)
        grid.addWidget(self.variable_a, 2, 4)
        
        grid.addWidget(QLabel('coef. b:'), 3, 3)
        self.variable_b = QDoubleSpinBox(minimum=-10, maximum=10, value=self.b, singleStep=0.1)
        self.variable_b.valueChanged.connect(self.update_variable_b)
        grid.addWidget(self.variable_b, 3, 4)
        
        grid.addWidget(QLabel('coef. c:'), 4, 3)
        self.variable_c = QDoubleSpinBox(minimum=-10, maximum=10, value=self.c, singleStep=0.1)
        self.variable_c.valueChanged.connect(self.update_variable_c)
        grid.addWidget(self.variable_c, 4, 4)
        
        # PPM only
        label_Br = QLabel('Br (T):')
        label_Br.setFixedWidth(80)
        grid.addWidget(label_Br, 2, 5)
        self.variable_Br = QDoubleSpinBox(minimum=0.01, maximum=20, value=self.Br, singleStep=0.1)
        self.variable_Br.valueChanged.connect(self.update_variable_Br)
        self.variable_Br.setFixedWidth(80)
        grid.addWidget(self.variable_Br, 2, 6)
        
        grid.addWidget(QLabel('M:'), 3, 5)
        self.variable_M = QSpinBox(minimum=1, maximum=10, value=self.M, singleStep=1)
        self.variable_M.valueChanged.connect(self.update_variable_M)
        grid.addWidget(self.variable_M, 3, 6)
        
        grid.addWidget(QLabel('Height/period:'), 4, 5)
        self.variable_h = QDoubleSpinBox(minimum=0.01, maximum=10, value=self.h, singleStep=0.1)
        self.variable_h.valueChanged.connect(self.update_variable_h)
        grid.addWidget(self.variable_h, 4, 6)
        
        # blank column
        blank_column7 = QLabel('')
        grid.addWidget(blank_column7, 0, 7)
        blank_column7.setFixedWidth(10)
        
        # plot setting
        grid.addWidget(QLabel('Plot ranges'), 0, 8, 1, 2)
        
        label_period = QLabel('Period (mm)')
        label_period.setFixedWidth(80)
        grid.addWidget(label_period, 1, 9)
        
        label_initial = QLabel('Initial:')
        label_initial.setFixedWidth(80)
        grid.addWidget(label_initial, 2, 8)
        self.period_initial = QDoubleSpinBox(minimum=1, maximum=1000, value=self.lu_0, singleStep=1)
        self.period_initial.valueChanged.connect(self.update_period_initial)
        grid.addWidget(self.period_initial, 2, 9)
        
        grid.addWidget(QLabel('End:'), 3, 8)
        self.period_end = QDoubleSpinBox(minimum=1, maximum=1000, value=self.lu_1, singleStep=1)
        self.period_end.valueChanged.connect(self.update_period_end)
        grid.addWidget(self.period_end, 3, 9)
        
        grid.addWidget(QLabel('Points:'), 4, 8)
        self.period_points = QSpinBox(minimum=2, maximum=1001, value=self.lu_pnt, singleStep=10)
        self.period_points.valueChanged.connect(self.update_period_points)
        grid.addWidget(self.period_points, 4, 9)
        
        label_K = QLabel('K')
        label_K.setFixedWidth(80)
        grid.addWidget(label_K, 1, 10)
        self.K_initial = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.K_0, singleStep=1)
        self.K_initial.valueChanged.connect(self.update_K_initial)
        grid.addWidget(self.K_initial, 2, 10)
        
        self.K_end = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.K_1, singleStep=1)
        self.K_end.valueChanged.connect(self.update_K_end)
        grid.addWidget(self.K_end, 3, 10)
        
        self.K_points = QSpinBox(minimum=2, maximum=1001, value=self.K_pnt, singleStep=10)
        self.K_points.valueChanged.connect(self.update_K_points)
        grid.addWidget(self.K_points, 4, 10)
        
        label_gap = QLabel('Gap (mm)')
        label_gap.setFixedWidth(80)
        grid.addWidget(label_gap, 1, 11)
        self.gap_initial = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.gap_0, singleStep=1)
        self.gap_initial.valueChanged.connect(self.update_gap_initial)
        grid.addWidget(self.gap_initial, 2, 11)
        
        self.gap_end = QDoubleSpinBox(minimum=0.1, maximum=100, value=self.gap_1, singleStep=1)
        self.gap_end.valueChanged.connect(self.update_gap_end)
        grid.addWidget(self.gap_end, 3, 11)
        
        self.gap_points = QSpinBox(minimum=2, maximum=1001, value=self.gap_pnt, singleStep=1)
        self.gap_points.valueChanged.connect(self.update_gap_points)
        grid.addWidget(self.gap_points, 4, 11)
        
        label_flux = QLabel('Flux (b)')
        label_flux.setFixedWidth(80)
        grid.addWidget(label_flux, 1, 12)
        self.flux_initial = QSpinBox(minimum=1, maximum=22, value=self.flux_0, singleStep=1)
        self.flux_initial.valueChanged.connect(self.update_flux_initial)
        grid.addWidget(self.flux_initial, 2, 12)
        
        self.flux_end = QSpinBox(minimum=1, maximum=22, value=self.flux_1, singleStep=1)
        self.flux_end.valueChanged.connect(self.update_flux_end)
        grid.addWidget(self.flux_end, 3, 12)
        
        label_energy = QLabel('Energy (keV)')
        label_energy.setFixedWidth(80)
        grid.addWidget(label_energy, 1, 13)
        self.energy_initial = QDoubleSpinBox(minimum=0.01, maximum=100, value=self.energy_0, singleStep=1)
        self.energy_initial.valueChanged.connect(self.update_energy_initial)
        grid.addWidget(self.energy_initial, 2, 13)
        
        self.energy_end = QDoubleSpinBox(minimum=0.01, maximum=100, value=self.energy_1, singleStep=1)
        self.energy_end.valueChanged.connect(self.update_energy_end)
        grid.addWidget(self.energy_end, 3, 13)
        
        # blank column
        blank_column14 = QLabel('')
        grid.addWidget(blank_column14, 0, 14)
        
        # blank line
        blank_space = QLabel('')
        grid.addWidget(blank_space, 5, 0)
        blank_space.setFixedHeight(10)
        
        # Slider to optimize the period and K
        self.lu_t = 20
        self.K_t = 2.03
        # adjustable lu and K in flux
        grid.addWidget(QLabel('Target period (mm):'), 7, 3)
        self.target_period = QDoubleSpinBox(minimum=1, maximum=1000, value=self.lu_t, singleStep=0.1)
        self.target_period.valueChanged.connect(self.calc_target_K)
        grid.addWidget(self.target_period, 7, 4)
        
        self.slider_target_period = QSlider(Qt.Orientation.Horizontal)
        self.slider_target_period.setRange(1,100)
        self.slider_target_period.setSingleStep(1)
        self.slider_target_period.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.slider_target_period.setValue(self.lu_t)
        self.slider_target_period.valueChanged.connect(self.target_period.setValue)
        grid.addWidget(self.slider_target_period, 7, 5, 1, 2)
        
        grid.addWidget(QLabel('Target K:'), 7, 8)
        self.target_K = QDoubleSpinBox(minimum=0.1, maximum=10, value=self.K_t, singleStep=0.1)
        self.target_K.valueChanged.connect(self.calc_target_K_t)
        grid.addWidget(self.target_K, 7, 9)
        
        self.slider_target_K = QSlider(Qt.Orientation.Horizontal)
        self.slider_target_K.setRange(0.1,10)
        self.slider_target_K.setSingleStep(1)
        self.slider_target_K.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.slider_target_K.setTickInterval(1)
        self.slider_target_K.setValue(self.K_t)
        self.slider_target_K.valueChanged.connect(self.target_K.setValue)
        grid.addWidget(self.slider_target_K, 7, 10, 1, 2)
        
        self.calc()
        self.show()
        
    def calc_target_K(self):
        self.lu_t = self.target_period.value()
        self.K_t = 0.0934*self.lu_t*self.a*np.exp((self.gap_0/self.lu_t)*(self.b+self.c*(self.gap_0/self.lu_t)))
        self.target_K.setValue(self.K_t)
        self.slider_target_K.setValue(self.K_t)
        self.calc()
        
    def calc_target_K_t(self):
        self.K_t = self.target_K.value()
        self.calc()
        
    def update_beam_energy(self):
        self.I_e = self.beam_energy.value()
        self.calc()
        
    def update_beam_current(self):
        self.I_e = self.beam_current.value()
        self.calc()
        
    def update_undulator_length(self):
        self.u_length = self.undulator_length.value()
        self.calc()
        
    def update_harmonic_number(self):
        self.n_har = self.harmonic_number.value()
        self.calc()
        
    def update_variable_a(self):
        self.a = self.variable_a.value()
        self.calc()
        
    def update_variable_b(self):
        self.b = self.variable_b.value()
        self.calc()
        
    def update_variable_c(self):
        self.c = self.variable_c.value()
        self.calc()
        
    def update_variable_Br(self):
        self.Br = self.variable_Br.value()
        self.calc()
        
    def update_variable_M(self):
        self.M = self.variable_M.value()
        self.calc()
        
    def update_variable_h(self):
        self.h = self.variable_h.value()
        self.calc()
        
    def update_period_initial(self):
        self.lu_0 = self.period_initial.value()
        self.calc()
        
    def update_period_end(self):
        self.lu_1 = self.period_end.value()
        self.calc()
        
    def update_period_points(self):
        self.lu_pnt = self.period_points.value()
        self.calc()
        
    def update_K_initial(self):
        self.K_0 = self.K_initial.value()
        self.calc()
        
    def update_K_end(self):
        self.K_1 = self.K_end.value()
        self.calc()
        
    def update_K_points(self):
        self.K_pnt = self.K_points.value()
        self.calc()
        
    def update_gap_initial(self):
        self.gap_0 = self.gap_initial.value()
        self.calc()
        
    def update_gap_end(self):
        self.gap_1 = self.gap_end.value()
        self.calc()
        
    def update_gap_points(self):
        self.gap_pnt = self.gap_points.value()
        self.calc()
        
    def update_flux_initial(self):
        self.flux_0 = self.flux_initial.value()
        self.calc()
        
    def update_flux_end(self):
        self.flux_1 = self.flux_end.value()
        self.calc()
        
    def update_energy_initial(self):
        self.energy_0 = self.energy_initial.value()
        self.calc()
        
    def update_energy_end(self):
        self.energy_1 = self.energy_end.value()
        self.calc()
        
    def calc(self):
        hc = 1.23498*10**-6
        gamma = self.E_e/0.000511
        K0 = 0.1
        
        n_pnt = int((self.n_har+1)/2)
        lu = np.linspace(self.lu_0, self.lu_1, self.lu_pnt)
        K = np.linspace(self.K_0, self.K_1, self.K_pnt)
        gap = np.linspace(self.gap_0, self.gap_1, self.gap_pnt)
        n = np.linspace(1, self.n_har, n_pnt)
        Ky = np.linspace(K0, self.K_t, self.K_pnt)
        
        x1, y1 = np.meshgrid(lu, K)
        x2, y2 = np.meshgrid(lu, gap)
        x3, y3 = np.meshgrid(Ky, n)
        
        K_lu = hc*10**-3/(x1*10**-3*(1+y1**2/2)/(2*gamma**2)/self.n_har)
        
        Np = np.floor(self.u_length/self.lu_t*1000)
        Y = y3*(x3**2)/(4*(1+x3**2/2))
        Qk = (y3/(1+x3**2/2))*(x3**2*(jv((y3-1)/2,Y)-jv((y3+1)/2,Y))**2)
        fx = 1.431*10**14*Np*Qk*self.I_e
        en = hc*10**-3/((self.lu_t*10**-3/(2*gamma**2))*(1+x3**2/2)/y3)
        
        if self.comboBox_magnet.currentIndex() < 4:
            g = 0.0934*x2*self.a*np.exp((y2/x2)*(self.b+self.c*(y2/x2)))
        else:
            g = 0.0934*x2*2*self.Br*(np.sin(np.pi/self.M)/(np.pi/self.M))*np.exp(-np.pi*(y2/x2))*(1-np.exp(-2*np.pi*self.h))
        
        self.ax1.cla()
        self.ax2.cla()
        
        self.ax1.set_title('Photon energy (keV)')
        self.ax2.set_title('Flux vs energy')

        cntr = self.ax1.contour(x1, y1, K_lu, 20, cmap='turbo')
        self.ax1.clabel(cntr, fmt="%2.1f", use_clabeltext=True)

        for i in range(self.gap_pnt):
            self.ax1.plot(lu, g[i,:], lw=2, label='str(gap[i]) mm')
            if i == 0:
                self.ax1.annotate(' Gap (mm)', xy=(self.lu_1, g[i,-1]+0.1))
            self.ax1.annotate(' ' +str(gap[i]), xy=(self.lu_1, g[i,-1]))
        
        self.ax1.set_xlim(self.lu_0, self.lu_1)
        self.ax1.set_ylim(self.K_0, self.K_1)
        
        self.ax1.grid()
        self.ax1.set_xlabel("Period (mm)")
        self.ax1.set_ylabel("K")
        #print(en[0,:])
        for i in range(n_pnt):
            self.ax2.loglog(en[i,:], fx[i,:], lw=2)
            self.ax2.annotate(str(int(n[i])), xy=(en[i,-1], fx[i,-1]))
        
        self.ax1.plot(self.lu_t, self.K_t, marker = 'o', ms = 10, mec = 'hotpink', mfc = 'hotpink')
        #self.ax1.annotate('target', xy=(self.lu_t, self.K_t))
        
        #crosshairs(xlabel='Period',ylabel='K',decimals=1)
        self.ax2.set_xlim([self.energy_0, self.energy_1]) 
        self.ax2.set_ylim([10**self.flux_0, 10**self.flux_1])
        
        self.ax2.get_xaxis().get_major_formatter().labelOnlyBase = False
        #self.ax2.set_xticks([0.5,0.6,0.7,0.8,0.9,1,2,3,4,5,6,7,8,9,10,20,30,40,50])
        #self.ax2.set_xticks([1,2,3,4,5,6,7,8,9,10])
        
        self.ax2.set_xlabel("Energy (keV)")
        self.ax2.set_ylabel("Flux (ph/s/0.1%bw)")
        self.ax2.grid(which='minor', alpha=0.3)
        self.ax2.grid(which='major', alpha=1)
        
        self.canvas.draw()
        #self.repaint()
        
    def magnet(self):
        if self.comboBox_magnet.currentIndex() == 0:
            self.variable_a.setValue(self.PPMU[0])
            self.variable_b.setValue(self.PPMU[1])
            self.variable_c.setValue(self.PPMU[2])
        elif self.comboBox_magnet.currentIndex() == 1:
            self.variable_a.setValue(self.HYBU[0])
            self.variable_b.setValue(self.HYBU[1])
            self.variable_c.setValue(self.HYBU[2])
        elif self.comboBox_magnet.currentIndex() == 2:
            self.variable_a.setValue(self.CPMU[0])
            self.variable_b.setValue(self.CPMU[1])
            self.variable_c.setValue(self.CPMU[2])
        elif self.comboBox_magnet.currentIndex() == 3:
            self.variable_a.setValue(self.SCMU[0])
            self.variable_b.setValue(self.SCMU[1])
            self.variable_c.setValue(self.SCMU[2])
        
        self.a = self.variable_a.value()
        self.b = self.variable_b.value()
        self.c = self.variable_c.value()
        
        self.calc()
        
        
    def center(self):
        qr = self.frameGeometry()
        cp = QtWidgets.QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())
  
    
    def closeEvent(self, event):
        event.accept()
        sys.exit(0)    

if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    w = PrettyWidget()
    sys.exit(app.exec_())
