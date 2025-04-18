﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "Macros"
	"Undulator"
End

// Hideki NAKAJIMA (c) 2024.01.18, rev. 2024.02.14
// load delimited text "XAS_edges.txt" for Flux/en plot

Function Undulator() : Panel
	String saveDF = GetDataFolder(1), panelun = "Undulator", homeDF = "root:un"
	
	DoWindow panelun
	if (V_flag == 1)
		DoWindow/F panelun
		Abort
	endif
	
	If (DataFolderExists("un") ==0)
		NewDataFolder/O/S root:un
		Variable/G loadpos = 10 
		// default: winsize = 1, winpos = 910, w_width=300, w_height=350
		// macbook11: winsize = 1, winpos = 400, w_width=900, w_height=700
		Variable/G winsize = 2, winpos = 400, w_width=900, w_height=700
		Variable/G E_e = 3, I_e = 0.30, u_length = 2000, n_har = 7, ph_err = 0
		Variable/G T_a = 2.076, T_b = -3.24, T_c = 0, crev, gplot, xplot, K_max = 5
		Variable/G PPM_a = 2.076, PPM_b = -3.24, PPM_c = 0, Br = 1.38, M = 4, h_lu_r = 0.5
		Variable/G HYB_a = 3.694, HYB_b = -5.068, HYB_c = 1.52 // https://doi.org/10.1016/S0168-9002(00)00544-1
		Variable/G HFe_a = 3.381, HFe_b = -4.73, HFe_c = 1.198 // https://doi.org/10.1016/S0168-9002(00)00544-1
		Variable/G HCo_a = 3.33, HCo_b = -5.47, HCo_c = 1.8 // https://doi.org/10.1016/j.nima.2005.03.150 or 10.1051/jphyscol:1983120
		Variable/G CPM_a = 3.502, CPM_b = -3.604, CPM_c = 0.359 // https://publications.anl.gov/anlpubs/2017/07/137001.pdf
		Variable/G CPH_a = 4.625, CPH_b = -5.251, CPH_c = 2.079 // https://doi.org/10.1103/PhysRevAccelBeams.20.064801
		Variable/G SCM_a = 12.42, SCM_b = -4.79, SCM_c = 0.385 // https://doi.org/10.1016/S0168-9002(00)00544-1
		// SCM(Kim) // https://doi.org/10.1016/j.nima.2005.03.150
		// ref. https://doi.org/10.3389/fphy.2023.1204073
		Variable/G lu_0 = 15, lu_1 = 25, lu_t = 20, lu_pnt = 71, K_0 = 1, K_1 = 3, K_t = 2, K_pnt = 21
		Variable/G gap_0 = 4, gap_1 = 5.5, gap_pnt = 4, gap_lu_0 = 0.001, gap_lu_1 = 1 // limit of gap/lu range, default 0.1 < gap/lu < 1.0
		Variable/G fld_0 = 1, fld_1 = 8, fld_pnt = 100, iplot=0
		Variable/G sigma_xr = 97.44, sigma_yr = 3.9, sigma_xd = 9.754, sigma_yd = 2.437, pe_wigg = 50, max_power = 25
		Variable/G emi_x = 9.6E-10, emi_y = 9.6E-12, beta_x = 9.99, beta_y = 1.6, esp = 0.00077 // emi9.5E-10/7.6E-12, beta9.95/1.6, esp0.00077
		Variable/G coupling = emi_y/emi_x // 0.01
		String/G lu_str= "Period "+num2str(lu_t), K_str = "max K "+num2str(K_t)
	else
		SetDataFolder root:un
		//String/G File_Name, Full
		Variable/G E_e, I_e, u_length, n_har, T_a, T_b, T_c, crev, gplot, xplot, PPM_a, PPM_b, PPM_c, HYB_a, HYB_b, HYB_c, Br, M, h_lu_r, ph_err
		Variable/G CPM_a, CPM_b, CPM_c, SCM_a, SCM_b, SCM_c, fld_0, fld_1, fld_pnt, iplot
		Variable/G lu_0, lu_1, lu_t, lu_pnt, K_0, K_1, K_t, K_pnt, gap_0, gap_1, gap_pnt, gap_lu_0, gap_lu_1, K_max
		Variable/G winsize, winpos, loadpos, w_width, w_height
		Variable/G sigma_xr, sigma_yr, sigma_xd, sigma_yd, pe_wigg, max_power
		Variable/G emi_x, emi_y, beta_x, beta_y, esp, coupling
		String/G lu_str, K_str
	endif
	
	NewPanel /W=(loadpos,10,loadpos+370,550)/N=panelun as "Undulator"
	
	TitleBox tit_un_opt,title="Machine parameters",pos={10,10},size={100, 40},fsize=14,frame=0
	SetVariable setE_e pos={10,40},size={150,30},title="Beam energy (GeV):",limits={0.1,10,0},value=E_e, proc = set_E_e
	SetVariable setI_e pos={10,60},size={150,30},title="Beam current (A):",limits={0.0001,10,0},value=I_e, proc = set_I_e
	SetVariable setu_length pos={10,80},size={150,30},title="Total length (mm):",limits={10,10000,0},value=u_length, proc = set_u_length
	SetVariable setn_har pos={10,100},size={150,30},title="Harmonics (odd):",limits={1,1001,2},value=n_har, proc = set_n_har
	TitleBox tit_lambda_u_range,title="Undulator period (mm)",pos={10,130},size={100, 20},frame=0
	TitleBox tit_lambda_u_0,title="Initial:",pos={10,145},size={50, 20},frame=0
	TitleBox tit_lambda_u_1,title="End:",pos={60,145},size={50, 20},frame=0
	TitleBox tit_lambda_u_p,title="# points:",pos={110,145},size={50, 20},frame=0
	SetVariable setlu_0 pos={10,160},size={50,30},title=" ",limits={0.1,300,0},value=lu_0, proc = set_lu_0
	SetVariable setlu_1 pos={60,160},size={50,30},title=" ",limits={0.1,300,0},value=lu_1, proc = set_lu_1
	SetVariable setlu_pnt pos={110,160},size={50,30},title=" ",limits={2,10001,0},value=lu_pnt, proc = set_lu_pnt
	TitleBox tit_K_range,title="K parameter",pos={10,185},size={100, 20},frame=0
	TitleBox tit_K_0,title="Initial:",pos={10,200},size={50, 20},frame=0
	TitleBox tit_K_1,title="End:",pos={60,200},size={50, 20},frame=0
	TitleBox tit_K_p,title="# points:",pos={110,200},size={50, 20},frame=0
	SetVariable setK_0 pos={10,215},size={50,30},title=" ",limits={0.01,20,0},value=K_0, proc = set_K_0
	SetVariable setK_1 pos={60,215},size={50,30},title=" ",limits={0.1,50,0},value=K_1, proc = set_K_1
	SetVariable setK_pnt pos={110,215},size={50,30},title=" ",limits={2,10001,0},value=K_pnt, proc = set_K_pnt
	
	TitleBox tit_e,title="Emittance",pos={10,255},size={50, 20},frame=0
	TitleBox tit_x,title="x",pos={100,255},size={50, 20},frame=0
	TitleBox tit_y,title="y",pos={150,255},size={50, 20},frame=0
	
	SetVariable setE_x pos={10,275},size={100,30},title="(m rad):",limits={1E-15,1,0},value=emi_x,format="%.2e", proc = set_E_x
	SetVariable setE_y pos={110,275},size={50,30},title=" ",limits={1E-15,1,0},value=emi_y,format="%.2e", proc = set_E_y
	SetVariable setB_x pos={10,295},size={100,30},title="beta (m):",limits={0.1,1000,0},value=beta_x, proc = set_B_x
	SetVariable setB_y pos={110,295},size={50,30},title=" ",limits={0.1,1000,0},value=beta_y, proc = set_B_y
	
	SetVariable setS_xr pos={10,315},size={100,30},title="s_r (um):",limits={0.1,1000,0},value=sigma_xr, proc = set_S_xr
	SetVariable setS_yr pos={110,315},size={50,30},title=" ",limits={0.1,1000,0},value=sigma_yr, proc = set_S_yr
	SetVariable setS_xd pos={10,335},size={100,30},title="s_d (urad):",limits={0.1,1000,0},value=sigma_xd, proc = set_S_xd
	SetVariable setS_yd pos={110,335},size={50,30},title=" ",limits={0.1,1000,0},value=sigma_yd, proc = set_S_yd
	
	SetVariable setEsp pos={10,355},size={150,30},title="Energy spread:",limits={0.0000001,1,0},value=esp, proc = set_esp
	SetVariable setCou pos={10,375},size={150,30},title="Coupling:",limits={0.0000001,1,0},value=coupling, proc = set_cou

	TitleBox tit_mag_est,title="Magnetic field simulation",pos={200,10},size={100, 20},fsize=14,frame=0
	PopupMenu setType pos={200,40},size={150,30},title="Magnet type:",value="PPM(a,b,c);HYB(a,b,c);HFe(a,b,c);HCo(a,b,c);CPM(a,b,c);CPH(a,b,c);SCM(a,b,c);SCK(Kim);Define(a,b,c);PPM(Br,M,h)",proc=set_Type_mag
	TitleBox tit_T_a,title="a:",pos={200,60},size={50, 20},frame=0
	TitleBox tit_T_b,title="b:",pos={250,60},size={50, 20},frame=0
	TitleBox tit_T_c,title="c:",pos={300,60},size={50, 20},frame=0
	SetVariable setT_a pos={200,75},size={50,30},title=" ",limits={-20,20,0},value=T_a, proc = set_T_a
	SetVariable setT_b pos={250,75},size={50,30},title=" ",limits={-20,20,0},value=T_b, proc = set_T_b
	SetVariable setT_c pos={300,75},size={50,30},title=" ",limits={-20,20,0},value=T_c, proc = set_T_c
	TitleBox tit_Br,title="Br (T):",pos={200,95},size={50, 20},frame=0
	TitleBox tit_M,title="M:",pos={250,95},size={50, 20},frame=0
	TitleBox tit_h,title="h/lu:",pos={300,95},size={50, 20},frame=0
	SetVariable setBr pos={200,110},size={50,30},title=" ",limits={0,10,0},value=Br, proc = set_Br
	SetVariable setM pos={250,110},size={50,30},title=" ",limits={1,10,0},value=M, proc = set_M
	SetVariable seth_lu_r pos={300,110},size={50,30},title=" ",limits={0.1,10,0},value=h_lu_r, proc = set_h_lu_r //PPM height/lambda_u
	
	TitleBox tit_gap_est,title="Gap range (mm)",pos={200,130},size={100, 20},frame=0
	TitleBox tit_gap_0,title="Initial:",pos={200,145},size={50, 20},frame=0
	TitleBox tit_gap_1,title="End:",pos={250,145},size={50, 20},frame=0
	TitleBox tit_gap_p,title="# points:",pos={300,145},size={50, 20},frame=0
	SetVariable setGap_0 pos={200,160},size={50,30},title=" ",limits={0.001,200,0},value=gap_0, proc = set_gap_0
	SetVariable setGap_1 pos={250,160},size={50,30},title=" ",limits={0.001,200,0},value=gap_1, proc = set_gap_1
	SetVariable setGap_pnt pos={300,160},size={50,30},title=" ",limits={2,10001,0},value=gap_pnt, proc = set_gap_pnt
	
	PopupMenu setMode pos={200,190},size={100,30},title="Mode:", value ="Linear(n>0,Kx=0,Ky);Helical(n=1,Kx=Ky)", proc = set_mode
	
	PopupMenu setDataType pos={200,210},size={150,30},title="Data:",value="PE (keV);F(K,n);Flux (ph/s/0.1%bw);AFD (ph/s/mrad2/0.1%bw);Beam size (um);Divergence (urad);CF x;CF y;Coherent fraction;Brilliance;Total power (kW);Angular PD (kW/mrad2);Eff. AFD;Eff. br1;Eff. br2 (details in code);Eff. flux",proc=set_data_type
	PopupMenu setPlotType pos={200,230},size={150,30},title="Plot:",value="Contour;Image",proc=set_plot_type
	PopupMenu setColorType pos={200,250},size={150,30},mode=3,value="*COLORTABLEPOPNONAMES*",proc=set_color_type
	CheckBox setColorRev pos={200,270},title="Rev. color:",side=1,value=crev,proc=set_color_rev
	CheckBox setGapPlot pos={275,270},title="Gap plot:",side=1,value=gplot,proc=set_gap_plot
	PopupMenu setPlotGap pos={200,290},size={150,30},title="Gap vs period:",value="Gap/lu;Field (T);K",proc=set_plot_gap
	
	//TitleBox tit_plotOther,title="Others:",pos={200,305},size={50,20},frame=0
	PopupMenu setPlotOther pos={200,315},size={150,30},title="Others:",value="Phase error;Flux(n),eV;AFD,eV;Bri,eV;F(K,n),K;F(K,n),eV;Q(K,n),K;G(K);Size (um);Div. (urad);CF x;CF y;CF;eff bri,eV;eff flux,eV",proc=set_plot_other
	CheckBox setBMPlot pos={325,315},title="B/W",side=1,value=xplot,proc=set_BM_plot
	//TitleBox tit_lu,title="Period:",variable=lu_str,pos={200,330},size={50, 20},frame=0
	//TitleBox tit_K,title="max K:",variable=K_str,pos={200,350},size={50, 20},frame=0
	SetVariable setluscale pos={200,335},size={90,30},title="Period:",limits={1,100,0.1},value=lu_t, proc = set_lu_scale
	Slider/Z luscale, pos={290,335},size={70,10},vert=0,ticks=0,side=1,value=lu_t,variable=lu_t,limits={1,100,0.1}, proc=luscaleproc,fColor=(0,1000,0)
	SetVariable setKscale pos={200,355},size={90,30},title="max K:",limits={0.1,5,0.1},value=K_t, proc = set_K_scale
	Slider/Z Kscale, pos={290,355},size={70,10},vert=0,ticks=0,side=1,value=K_t,variable=K_t,limits={0.1,5,0.1}, proc=Kscaleproc,fColor=(0,1000,0)
	SetVariable setpherr pos={200,375},size={150,30},title="Phase error (deg):",limits={0,10,1},value=ph_err, proc = set_ph_err
	
	PopupMenu setPlotWigg pos={200,400},size={150,30},title="Wiggler",value="Flux < Pmax;AFD < Pmax;AFD at L in W;AFD at L in U;Flux at L in U;eff F at L in U",proc=set_plot_wigg
	PopupMenu setAddWigg pos={200,420},size={150,30},title="Addtional",value="Angle,mrad;Harmonic #;K;# periods;P,kW/m;P,kW/ID;Total length,m",proc=set_add_wigg
	SetVariable setpewigg pos={200,440},size={150,30},title="Photon energy (keV):",limits={0.01,200,1},value=pe_wigg, proc = set_pe_wigg
	SetVariable setmaxpw pos={200,460},size={150,30},title="Power max (kW):",limits={0.01,200,1},value=max_power, proc = set_max_power
	
	TitleBox tit_fld_est,title="Field range (T)",pos={200,480},size={100, 20},frame=0
	CheckBox setImgPlot pos={300,480},title="Img:",side=1,value=iplot,proc=set_img_plot
	TitleBox tit_fld_0,title="Initial:",pos={200,495},size={50, 20},frame=0
	TitleBox tit_fld_1,title="End:",pos={250,495},size={50, 20},frame=0
	TitleBox tit_fld_p,title="# points:",pos={300,495},size={50, 20},frame=0
	SetVariable setfld_0 pos={200,510},size={50,30},title=" ",limits={0.1,10,1},value=fld_0, proc = set_fld_0
	SetVariable setfld_1 pos={250,510},size={50,30},title=" ",limits={0.1,10,1},value=fld_1, proc = set_fld_1
	SetVariable setfld_pnt pos={300,510},size={50,30},title=" ",limits={2,10001,1},value=fld_pnt, proc = set_fld_pnt

	SetDataFolder saveDF
End

Function/S targetName(varNum)
	Variable varNum
	string wn, data, unit
	
	Controlinfo/W=panelun setDataType
	if (V_Value == 1)	// photon energy (keV)
		wn = "K_lu_en"
		data = "Photon energy"
		unit = "keV"
	elseif (V_Value == 2)	// F(K,n)
		wn = "K_lu_fk"
		data = "F(K,n)"
		unit = ""
	elseif (V_Value == 3)	// Flux in the central cone (ph/s/0.1%bw); zero emittance or energy spread
		wn = "K_lu_fl"
		data = "Flux in the central cone"
		unit = "ph/s/0.1%bw"
	elseif (V_Value == 4)	// Angular flux density (ph/s/mrad2/0.1%bw); zero emittance or energy spread
		wn = "K_lu_af"
		data = "Angular flux density"
		unit = "ph/s/mrad\S2\M/0.1%bw"
	elseif (V_Value == 5)	// Beam size (um); zero emittance or energy spread
		wn = "K_lu_sr"
		data = "Beam size"
		unit = "um"
	elseif (V_Value == 6)	// Beam divergence (umrad); zero emittance or energy spread
		wn = "K_lu_sd"
		data = "Beam divergence"
		unit = "umrad"
	elseif (V_Value == 7)	// Coherent fraction in x
		wn = "K_lu_cx"
		data = "Coherent fraction in x"
		unit = ""
	elseif (V_Value == 8)	// Coherent fraction in y
		wn = "K_lu_cy"
		data = "Coherent fraction in y"
		unit = ""
	elseif (V_Value == 9)	// Coherent fraction
		wn = "K_lu_cf"
		data = "Coherent fraction"
		unit = "keV"
	elseif (V_Value == 10)	// Brilliance (ph/s/mm2/mrad2/0.1%bw); zero emittance or energy spread
		wn = "K_lu_br"
		data = "Brilliance"
		unit = "ph/s/mm\S2\M/mrad\S2\M/0.1%bw"
	elseif (V_Value == 11)	// Total power (kW); zero emittance or energy spread
		wn = "K_lu_tp"
		data = "Total power"
		unit = "kW"
	elseif (V_Value == 12)	// Angular power density (kW/mrad2); zero emittance or energy spread
		wn = "K_lu_ap"
		data = "Angular power density"
		unit = "kW/mrad2"
	elseif (V_Value == 13)	// Effective angular flux density
		wn = "K_lu_eaf"
		data = "Effective angular flux density"
		unit = "ph/s/mm\S2\M/mrad\S2\M/0.1%bw"
	elseif (V_Value == 14)	// Effective brilliance 1 (sigma_r,d and beam size,divergence)
		wn = "K_lu_ebr1"
		data = "Effective brilliance (sigma_r,d and beam size,divergence)"
		unit = "ph/s/mm\S2\M/mrad\S2\M/0.1%bw"
	elseif (V_Value == 15)	// Effective brilliance 2 (Emittance, beta, energy spread, and phase error)
		wn = "K_lu_ebr2"
		data = "Effective brilliance 2 (Emittance, beta and energy spread, phase error)"
		unit = "ph/s/mm\S2\M/mrad\S2\M/0.1%bw"
	elseif (V_Value == 16)	// Effective brilliance 2 (Emittance, beta, energy spread, and phase error)
		wn = "K_lu_efl"
		data = "Effective flux from eff bri 2 (Emittance, beta and energy spread, phase error)"
		unit = "ph/s/0.1%bw"
	endif
	
	if (varNum == 1)
		return wn
	elseif (varNum == 2)
		return data
	elseif (varNum == 3)
		return unit
	endif
end

Function B_un_plot()
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt, K_0 = root:un:K_0, K_1 = root:un:K_1, K_pnt = root:un:K_pnt
	NVAR crev = root:un:crev, gplot = root:un:gplot, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, n_har = root:un:n_har
	
	String wn = targetName(1), plot_type, color_type, w_tmp, gapstr, str_tag, str_tag_list, gap_list, gap_wave
	Variable i = 0, d_gap = (gap_1 - gap_0)/(gap_pnt-1), gap_plot, color_rev, plot_tran
	Variable lu = lu_1-(lu_1-lu_0)/10	// Tag position of gap (mm)
	
	Controlinfo/W=panelun setPlotType
	if (V_Value == 1)
		plot_type = "c"
		plot_tran = 0
	else
		plot_type = "i"
		plot_tran = 1
	endif
	
	String topGraphName = "Un_plot_" + plot_type + "_" + wn
	
	Controlinfo/W=panelun setGapPlot
	gap_plot = V_Value
	
	Controlinfo/W=panelun setColorRev
	color_rev = V_Value
	
	Controlinfo/W=panelun setColorType
	color_type = S_Value
	
	DoWindow $topGraphName
	if (V_flag == 1)
		DoWindow/F $topGraphName
		if (stringmatch(plot_type,"c")==1)
			ModifyContour/W=$topGraphName $wn ctabLines={*,*,$color_type,color_rev}
		else
			ModifyImage/W=$topGraphName $wn ctab= {*,*,$color_type,color_rev}
		endif
		
		SetAxis/W=$topGraphName left K_0, K_1
		SetAxis/W=$topGraphName bottom lu_0, lu_1
		TextBox/W=$topGraphName/C/N=$topGraphName/F=0/A=LT targetName(2)+" ("+targetName(3)+")\r"+num2str(E_e)+" GeV, "+num2str(I_e*1000)+" mA, "+num2str(u_length/1000)+" m, "+"har. "+num2str(n_har)
			
		String w_list = TraceNameList(topGraphName, ";", 1), w_temp
		
		if (gap_plot==1)
			if (ItemsInList(w_list) <= 1)
				i = 0
				Do
					gapstr = num2str(gap_0+d_gap*i)
					AppendToGraph/W=$topGraphName $"Gap_lu_K_gap" + gapstr
					ModifyGraph/W=$topGraphName lsize($"Gap_lu_K_gap" + gapstr)=1.5
					ModifyGraph/W=$topGraphName rgb($"Gap_lu_K_gap" + gapstr)=(1,16019,65535)
					ModifyGraph/W=$topGraphName grid=1,tick(left)=3,tick(bottom)=2,minor=1,gridStyle=3,gridRGB=(48059,48059,48059)
					if (plot_tran == 0)
						Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
					else
						Tag/A=RT/B=1/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
					endif
					setcolor()
					i = i + 1
				while(i < gap_pnt)
				
				i =0
				gap_list = WaveList("Gap_lu_K_gap*", ";", "DIMS:1")
				print ItemsInList(gap_list, ";")
				Do
					gap_wave = StringFromList(i, gap_list, ";")
					KillWaves/Z $gap_wave
					i = i + 1
				while(i < ItemsInList(gap_list, ";"))
			else
				i=0
				Do
					w_tmp = StringFromList(i, w_list, ";")
					RemoveFromGraph/W=$topGraphName $w_tmp
					i = i + 1
				while(i < ItemsInList(w_list))
				i=0
				Do
					gapstr = num2str(gap_0+d_gap*i)
					AppendToGraph/W=$topGraphName $"Gap_lu_K_gap" + gapstr
					ModifyGraph/W=$topGraphName lsize($"Gap_lu_K_gap" + gapstr)=1.5
					ModifyGraph/W=$topGraphName rgb($"Gap_lu_K_gap" + gapstr)=(1,16019,65535)
					ModifyGraph/W=$topGraphName grid=1,tick(left)=3,tick(bottom)=2,minor=1,gridStyle=3,gridRGB=(48059,48059,48059)
					if (plot_tran == 0)
						Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
					else
						Tag/A=RT/B=1/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
					endif
					setcolor()
					i = i + 1
				while(i < gap_pnt)
				
				i =0
				gap_list = WaveList("Gap_lu_K_gap*", ";", "DIMS:1")
				print ItemsInList(gap_list, ";")
				Do
					gap_wave = StringFromList(i, gap_list, ";")
					KillWaves/Z $gap_wave
					i = i + 1
				while(i < ItemsInList(gap_list, ";"))
			endif
		else
			if (ItemsInList(w_list) > 1)
				i=0
				Do
					w_tmp = StringFromList(i, w_list, ";")
					RemoveFromGraph/W=$topGraphName $w_tmp
					i = i + 1
				while(i < ItemsInList(w_list))
			endif
		endif
	else
		Display/N=$topGraphName/W=(winpos, 10, winpos+w_width/winsize, 10+w_height/winsize)
		
		if (stringmatch(plot_type,"c")==1)
			AppendMatrixContour/W=$topGraphName $wn
			ModifyContour/W=$topGraphName $wn ctabLines={*,*,$color_type,color_rev}
			ModifyContour/W=$topGraphName $wn autoLevels={*,*,10}
			
			if (stringmatch(wn,"K_lu_en")==1)	// Se K edge for Se-MAD
				ModifyContour/W=$topGraphName $wn moreLevels=0,moreLevels={12.4}
				ModifyGraph/W=$topGraphName lsize($wn+"=12.4")=2,rgb($wn+"=12.4")=(65535,0,0)
			endif
		else
			AppendImage/W=$topGraphName $wn
			ModifyImage/W=$topGraphName $wn ctab= {*,*,$color_type,color_rev}
			//Showinfo/W=$"Un_plot_" + plot_type + "_" + wn
		endif
		
		Label/W=$topGraphName left "K"
		SetAxis/W=$topGraphName left K_0, K_1
		SetAxis/W=$topGraphName bottom lu_0, lu_1
		ModifyGraph/W=$topGraphName mirror=2
		ModifyGraph/W=$topGraphName grid=1,tick(left)=3,tick(bottom)=2,minor=1,gridStyle=3,gridRGB=(48059,48059,48059)
		TextBox/W=$topGraphName/C/N=$topGraphName/F=0/A=LT targetName(2)+" ("+targetName(3)+")\r"+num2str(E_e)+" GeV, "+num2str(I_e*1000)+" mA, "+num2str(u_length/1000)+" m, "+"har. "+num2str(n_har)
		
		if (gap_plot==1)
			i=0
			Do
				gapstr = num2str(gap_0+d_gap*i)
				AppendToGraph/W=$topGraphName $"Gap_lu_K_gap" + gapstr
				ModifyGraph/W=$topGraphName lsize($"Gap_lu_K_gap" + gapstr)=1.5
				ModifyGraph/W=$topGraphName rgb($"Gap_lu_K_gap" + gapstr)=(1,16019,65535)
				if (plot_tran == 0)
					Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
				else
					Tag/A=RT/B=1/F=0/I=0/L=0/Z=0/W=$topGraphName/X=1/y=1 $"Gap_lu_K_gap" + gapstr, lu, gapstr+" mm"
				endif
				setcolor()
				i = i + 1
			while(i < gap_pnt)
			
			i =0
			gap_list = WaveList("Gap_lu_K_gap*", ";", "DIMS:1")
			print ItemsInList(gap_list, ";")
			Do
				gap_wave = StringFromList(i, gap_list, ";")
				KillWaves/Z $gap_wave
				i = i + 1
			while(i < ItemsInList(gap_list, ";"))
		endif
	endif
	DoWindow/F panelun
End

Function Gap_lu_plot() // Gap vs lambda_u for gap/lu, field, K in contour plot
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, gap_0 = root:un:gap_0, gap_1 = root:un:gap_1
	//String topGraphName = WinName(0, 1), list = ContourNameList(topGraphName, ";"), wn = StringFromList(0, list, ";")
	String wn, strAno
	
	Controlinfo/W=panelun setPlotGap
	print V_Value
	if (V_Value == 1)
		wn = "Gap_lu"
		strAno = "Gap/period"
	elseif (V_Value == 2)
		wn = "Gap_lu_field_gap"
		strAno = "Field (T)"
	elseif (V_Value == 3)
		wn = "Gap_lu_K_gap"
		strAno = "K"
	endif
	
	DoWindow $"Un_plot_c_" + wn
	if (V_flag == 1)
		DoWindow/K $"Un_plot_c_" + wn
	endif
	
	Display/N=$"Un_plot_c_" + wn/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize)
	AppendMatrixContour/W=$"Un_plot_c_" + wn $wn
	SetAxis/W=$"Un_plot_c_" + wn left gap_0, gap_1
	SetAxis/W=$"Un_plot_c_" + wn bottom lu_0, lu_1
	ModifyContour/W=$"Un_plot_c_" + wn $wn autoLevels={*,*,21}
	ModifyGraph/W=$"Un_plot_c_" + wn grid=1,tick=2,minor=1,mirror=2,gridStyle=3,gridRGB=(48059,48059,48059)
	TextBox/W=$"Un_plot_c_" + wn/C/N=$"Un_plot_c_" + wn/F=0/A=LT strAno
	DoWindow/F panelun
end

Function Other_plots()
	NVAR lu_t = root:un:lu_t, K_t = root:un:K_t
	Controlinfo/W=panelun setPlotOther
	if (V_Value == 1)
		phaseError()
	elseif (V_Value > 1)
		calc_1d(lu_t,K_t)
		calc_1d_plot()
	endif
	DoWindow/F panelun
End

Function K_lu_energy()
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, n_har = root:un:n_har, emi_x = root:un:emi_x, emi_y = root:un:emi_y, beta_x = root:un:beta_x, beta_y = root:un:beta_y , esp = root:un:esp
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_t = root:un:lu_t, lu_pnt = root:un:lu_pnt, K_0 = root:un:K_0, K_1 = root:un:K_1, K_t = root:un:K_t, K_pnt = root:un:K_pnt
	NVAR sigma_xr = root:un:sigma_xr, sigma_yr = root:un:sigma_yr, sigma_xd = root:un:sigma_xd, sigma_yd = root:un:sigma_yd, ph_err = root:un:ph_err
	String savedDF = GetDataFolder(1), wn = targetName(1), plot_type
	
	Controlinfo/W=panelun setPlotType
	if (V_Value == 1)
		plot_type = "c"
	else
		plot_type = "i"
	endif
	
	String topGraphName = "Un_plot_" + plot_type + "_" + wn
	Variable i = 0, j = 0, d_lu = (lu_1 - lu_0)/(lu_pnt-1), d_K = (K_1 - K_0)/(K_pnt-1)
	Variable lu, K, N, hc = 1.2398*10^-6, gg=E_e/0.000511, eta_x, eta_y, mode
	
	Controlinfo/W=panelun setMode	// linear or helical (APPLE-II)
	mode = V_Value
	//printf num2str(V_Value)
	Make/D/N=(lu_pnt,K_pnt)/O K_lu_la, K_lu_en, K_lu_bt, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2, emi_r, K_lu_efl
	
	Do 
		j = 0
		lu = lu_0+d_lu*i
		Do
			K = K_0 + d_K*j
			N = floor(u_length/lu)
			if (mode == 1)
				K_lu_la[i][j] = ((lu*10^-3/(2*gg^2))*(1+K^2/2)/n_har) // wavelength (m)
			elseif (mode == 2)
				K_lu_la[i][j] = ((lu*10^-3/(2*gg^2))*(1+K^2)) // https://www.cockcroft.ac.uk/wp-content/uploads/2014/12/CLarke-Lecture-3.pdf
			endif
			K_lu_en[i][j] = ((10^-3)*(hc))/K_lu_la[i][j] // keV
			K_lu_bt[i][j] = K/(0.0934*lu) 	// Magnetic field (T)
			K_lu_fk[i][j] = ((n_har*K)^2/((1+K^2/2)^2))*(BESSELJ((n_har-1)/2,n_har*K^2/(4*(1+K^2/2)))-BESSELJ((n_har+1)/2,n_har*K^2/(4*(1+K^2/2))))^2
			if (mode == 1)
				K_lu_fl[i][j] = 1.431*10^14*N*(1+K^2/2)*(K_lu_fk[i][j]/n_har)*I_e // it depends on fk formula
				K_lu_af[i][j] = 1.7441*10^14*N^2*E_e^2*I_e*K_lu_fk[i][j] 
			elseif (mode == 2)
				K_lu_fl[i][j] = 2.86*10^14*N*I_e*K^2/(1+K^2)
				K_lu_af[i][j] = 3.49*10^14*N^2*E_e^2*I_e*(K/(1+K^2))^2
			endif
			
			K_lu_sr[i][j] = 10^6*SQRT(2*(u_length/1000)*K_lu_la[i][j])/(4*pi)
			K_lu_sd[i][j] = 10^6*SQRT(K_lu_la[i][j]/(2*(u_length/1000)))
			K_lu_cx[i][j] = (K_lu_sr[i][j]*K_lu_sd[i][j])/(SQRT(sigma_xr^2+K_lu_sr[i][j]^2)*SQRT(sigma_xd^2+K_lu_sd[i][j]^2)) // horizontal
			K_lu_cy[i][j] = (K_lu_sr[i][j]*K_lu_sd[i][j])/(SQRT(sigma_yr^2+K_lu_sr[i][j]^2)*SQRT(sigma_yd^2+K_lu_sd[i][j]^2)) // vertical
			K_lu_cf[i][j] = K_lu_cx[i][j]*K_lu_cy[i][j]
			//K_lu_cf[i][j] = (K_lu_sr[i][j]*K_lu_sd[i][j])^2/(SQRT(sigma_xr^2+K_lu_sr[i][j]^2)*SQRT(sigma_yr^2+K_lu_sr[i][j]^2)*SQRT(sigma_xd^2+K_lu_sd[i][j]^2)*SQRT(sigma_yd^2+K_lu_sd[i][j]^2))
			K_lu_br[i][j] = K_lu_fl[i][j]/(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^12
			//K_lu_ebr[i][j] = K_lu_fl[i][j]/(4*pi^2*SQRT(sigma_xr^2+K_lu_sr[i][j]^2)*SQRT(sigma_yr^2+K_lu_sr[i][j]^2)*SQRT(sigma_xd^2+K_lu_sd[i][j]^2)*SQRT(sigma_yd^2+K_lu_sd[i][j]^2))*10^12
			if (mode == 1)
				K_lu_tp[i][j] = 0.633*E_e^2*K_lu_bt[i][j]^2*I_e*u_length/1000
				K_lu_ap[i][j] = 10.84*K_lu_bt[i][j]*(E_e^4)*I_e*N/1000
			elseif (mode == 2)
				K_lu_tp[i][j] = 1.2655*E_e^2*K_lu_bt[i][j]^2*I_e*u_length/1000
				K_lu_ap[i][j] = 4.6257*K_lu_bt[i][j]^2*(E_e^4)*I_e*u_length/(1+K^2)^3/1000
			endif
			K_lu_eaf[i][j] = K_lu_af[i][j]*(K_lu_sd[i][j]^2/(SQRT(K_lu_sd[i][j]^2+sigma_xd^2)*SQRT(K_lu_sd[i][j]^2+sigma_yd^2)))
			// used in SPECTRA
			K_lu_ebr1[i][j] = K_lu_eaf[i][j]/(2*pi*SQRT(K_lu_sr[i][j]^2+sigma_xr^2)*SQRT(K_lu_sr[i][j]^2+sigma_yr^2))*10^6
			// https://doi.org/10.1103/PhysRevAccelBeams.20.064801
			emi_r[i][j] = K_lu_la[i][j]/(4*pi)
			eta_x = 2*pi*beta_x/(u_length/1000)
			eta_y = 2*pi*beta_y/(u_length/1000)
			emi_x = sigma_xr*sigma_xd*10^-12
			emi_y = sigma_yr*sigma_yd*10^-12
			K_lu_ebr2[i][j] = K_lu_fl[i][j]/(4*pi^2*SQRT(emi_r[i][j]^2+emi_x^2+emi_r[i][j]*emi_x*(eta_x+eta_x^-1))*SQRT(emi_r[i][j]^2+emi_y^2+emi_r[i][j]*emi_y*(eta_y+eta_y^-1)))*10^-12 // m rad -> mm mrad
			K_lu_ebr2[i][j] = K_lu_ebr2[i][j]/(sqrt(1+(5*n_har*N*esp)^2))	// energy spread effect
			K_lu_ebr2[i][j] = K_lu_ebr2[i][j]*(exp(-(n_har*ph_err*pi/180)^2))	// energy spread effect
			K_lu_efl[i][j] = K_lu_ebr2[i][j]*(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^-12
			j = j + 1
		while(j < K_pnt)
		i = i + 1
	while(i < lu_pnt)
	
	SetScale/I	x lu_0,lu_1,"Undulator period (mm)", K_lu_la, K_lu_en, K_lu_bt, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2, K_lu_efl
	SetScale/I	y K_0,K_1,"K", K_lu_la, K_lu_en, K_lu_bt, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2, K_lu_efl
	
	SetDataFolder savedDF
	//DoWindow/F panelun
	DoWindow $topGraphName
	if (V_flag == 1)
		TextBox/W=$topGraphName/C/N=$topGraphName/F=0/A=LT targetName(2)+" ("+targetName(3)+")\r"+num2str(E_e)+" GeV, "+num2str(I_e*1000)+" mA, "+num2str(u_length/1000)+" m, "+"har. "+num2str(n_har)
	endif
	
	//calc_1d(lu_t,K_t)
End

Function K_lu_energy_n()	// layer for 3D plot
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, n_har = root:un:n_har, emi_x = root:un:emi_x, emi_y = root:un:emi_y, beta_x = root:un:beta_x, beta_y = root:un:beta_y , esp = root:un:esp
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt, K_0 = root:un:K_0, K_1 = root:un:K_1, K_pnt = root:un:K_pnt
	NVAR sigma_xr = root:un:sigma_xr, sigma_yr = root:un:sigma_yr, sigma_xd = root:un:sigma_xd, sigma_yd = root:un:sigma_yd, ph_err = root:un:ph_err
	
	String savedDF = GetDataFolder(1)
	Variable i = 0, j = 0, k = 0, d_lu = (lu_1 - lu_0)/(lu_pnt-1), d_K = (K_1 - K_0)/(K_pnt-1), gg=E_e/0.000511
	Variable lu, Kp, hc = 1.2398*10^-6, n, n_pnt = (n_har+1)/2, Np, emi_r, eta_x, eta_y
	
	Make/D/N=(lu_pnt,K_pnt,n_pnt)/O K_lu_la, K_lu_en, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2
	
	i = 0
	Do 
		j = 0
		lu = lu_0+d_lu*i
		Do
			k = 0
			Do
				n = k*2+1	// harmonic number
				Kp = K_0 + d_K*j	// K parameter
				Np = floor(u_length/lu)	// number of periods
				K_lu_la[i][j][k] = ((lu*10^-3/(2*gg^2))*(1+Kp^2/2)/n) // m
				K_lu_en[i][j][k] = ((10^-3)*(hc))/((lu*10^-3/(2*gg^2))*(1+Kp^2/2)/n)
				K_lu_fk[i][j][k] = ((n*Kp)^2/((1+Kp^2/2)^2))*(BESSELJ((n-1)/2,n*Kp^2/(4*(1+Kp^2/2)))-BESSELJ((n+1)/2,n*Kp^2/(4*(1+Kp^2/2))))^2
				K_lu_fl[i][j][k] = 1.431*10^14*Np*(1+Kp^2/2)*(K_lu_fk[i][j][k]/n)*I_e
				K_lu_af[i][j][k] = 1.7441*10^14*Np^2*E_e^2*I_e*K_lu_fk[i][j][k] 
				K_lu_sr[i][j][k] = 10^6*SQRT(2*(u_length/1000)*(hc/(1000*K_lu_en[i][j][k])))/(4*pi)
				K_lu_sd[i][j][k] = SQRT((hc/(K_lu_en[i][j][k]*1000))/(2*(u_length/1000)))*10^6
				K_lu_cx[i][j][k] = (K_lu_sr[i][j][k]*K_lu_sd[i][j][k])/(SQRT(sigma_xr^2+K_lu_sr[i][j][k]^2)*SQRT(sigma_xd^2+K_lu_sd[i][j][k]^2)) // horizontal
				K_lu_cy[i][j][k] = (K_lu_sr[i][j][k]*K_lu_sd[i][j][k])/(SQRT(sigma_yr^2+K_lu_sr[i][j][k]^2)*SQRT(sigma_yd^2+K_lu_sd[i][j][k]^2)) // vertical
				K_lu_cf[i][j][k] = K_lu_cx[i][j][k]*K_lu_cy[i][j][k]
				K_lu_br[i][j][k] = K_lu_fl[i][j][k]/(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^12
				K_lu_tp[i][j][k] = 0.633*E_e^2*(Kp/(lu*0.0934))^2*I_e*u_length/1000
				K_lu_ap[i][j][k] = 10.84*(Kp/(lu*0.0934))*(E_e^4)*I_e*Np/1000
				K_lu_eaf[i][j][k] = K_lu_af[i][j][k]*(K_lu_sd[i][j][k]^2/(SQRT(K_lu_sd[i][j][k]^2+sigma_xd^2)*SQRT(K_lu_sd[i][j][k]^2+sigma_yd^2)))
				K_lu_ebr1[i][j][k] = K_lu_eaf[i][j][k]/(2*pi*SQRT(K_lu_sr[i][j][k]^2+sigma_xr^2)*SQRT(K_lu_sr[i][j][k]^2+sigma_yr^2))*10^6
				// https://doi.org/10.1103/PhysRevAccelBeams.20.064801
				emi_r = K_lu_la[i][j][k]/(4*pi)
				eta_x = 2*pi*beta_x/(u_length/1000)
				eta_y = 2*pi*beta_y/(u_length/1000)
				emi_x = sigma_xr*sigma_xd*10^-12
				emi_y = sigma_yr*sigma_yd*10^-12
				K_lu_ebr2[i][j][k] = K_lu_fl[i][j][k]/(4*pi^2*SQRT(emi_r^2+emi_x^2+emi_r*emi_x*(eta_x+eta_x^-1))*SQRT(emi_r^2+emi_y^2+emi_r*emi_y*(eta_y+eta_y^-1)))*10^-12 // m rad -> mm mrad
				K_lu_ebr2[i][j][k] = K_lu_ebr2[i][j][k]/(sqrt(1+(5*n*Np*esp)^2))
				K_lu_ebr2[i][j][k] = K_lu_ebr2[i][j][k]*(exp(-(n*ph_err*pi/180)^2))	// energy spread effect
				
				k = k + 1
			while(k < n_pnt)
			j = j + 1
		while(j < K_pnt)
		i = i + 1
	while(i < lu_pnt)
	
	SetScale/I	x lu_0,lu_1,"Undulator period (mm)", K_lu_la, K_lu_en, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2
	SetScale/I	y K_0,K_1,"K", K_lu_la, K_lu_en, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2
	SetScale/I	z 1,n_har,"Harmonic number", K_lu_la, K_lu_en, K_lu_fk, K_lu_fl, K_lu_af, K_lu_sr, K_lu_sd, K_lu_cx, K_lu_cy, K_lu_cf, K_lu_br, K_lu_tp, K_lu_ap, K_lu_eaf, K_lu_ebr1, K_lu_ebr2
	
	SetDataFolder savedDF
End

Function calc_1d(lu, K)
	Variable lu, K
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, n_har = root:un:n_har, ph_err = root:un:ph_err
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt, K_0 = root:un:K_0, K_1 = root:un:K_1, K_pnt = root:un:K_pnt
	NVAR sigma_xd = root:un:sigma_xd, sigma_yd = root:un:sigma_yd, sigma_xr = root:un:sigma_xr, sigma_yr = root:un:sigma_yr
	NVAR beta_x = root:un:beta_x, beta_y = root:un:beta_y, esp = root:un:esp
	Variable i, j, n, n_pnt = (n_har+1)/2, Kp, d_K = (K - K0)/(K_pnt-1), hc = 1.2398*10^-6, gg=E_e/0.000511, en_0, en_1, Np, mode
	Variable eta_x, eta_y, emi_x, emi_y
	String w = "I_1d", harstr, fl, af, fk, en, qk, gk, bt, br
	String la, sr, sd, cx, cy, cf, eaf, ebr, emr, efl
	
	Controlinfo/W=panelun setMode
	mode = V_Value
	if (mode == 2)
		n_pnt = 1
	endif
	
	K0 = 0.1	// minimum K instead of K_0
	
	i=0
	gk = w + "_gk"
	Make/D/N=(K_pnt)/O $gk
	Wave w_gk = $gk
	Np = floor(u_length/lu)
	
	Do
		n = i*2+1
		harstr = num2str(n)
		en = w + "_en_n" + harstr
		fk = w + "_fk_n" + harstr
		fl = w + "_fl_n" + harstr
		af = w + "_af_n" + harstr
		qk = w + "_qk_n" + harstr
		bt = w + "_bt_n" + harstr
		br = w + "_br_n" + harstr
		
		Make/D/N=(K_pnt)/O $fl, $af, $fk, $en, $"sd", $qk, $bt, $br
		Wave w_en = $en, w_fk = $fk, w_af = $af, w_fl = $fl, w_sd = $"sd", w_qk = $qk, w_bt = $bt, w_br = $br
		
		la = w + "_la_n" + harstr
		sr = w + "_sr_n" + harstr
		sd = w + "_sd_n" + harstr
		cx = w + "_cx_n" + harstr
		cy = w + "_cy_n" + harstr
		cf = w + "_cf_n" + harstr
		eaf = w + "_eaf_n" + harstr
		ebr = w + "_ebr_n" + harstr
		emr = w + "_emr_n" + harstr
		efl = w + "_efl_n" + harstr
		
		Make/D/N=(K_pnt)/O $la, $sr, $sd, $cx, $cy, $cf, $eaf, $ebr, $emr, $efl
		Wave w_la = $la, w_sr = $sr, w_sd = $sd, w_cx = $cx, w_cy = $cy, w_cf = $cf, w_eaf = $eaf, w_ebr = $ebr, w_emr = $emr, w_efl = $efl
		
		j=0
		Do
			Kp = K0 + d_K*j
			if (mode == 1)
				w_en[j] = ((10^-3)*(hc))/((lu*10^-3/(2*gg^2))*(1+Kp^2/2)/n)
			elseif (mode == 2)
				w_en[j] = ((10^-3)*(hc))/((lu*10^-3/(2*gg^2))*(1+Kp^2))
			endif
			w_fk[j] = ((n*Kp)^2/((1+Kp^2/2)^2))*(BESSELJ((n-1)/2,n*Kp^2/(4*(1+Kp^2/2)))-BESSELJ((n+1)/2,n*Kp^2/(4*(1+Kp^2/2))))^2
			w_qk[j] = (1+Kp^2/2)*(w_fk[j]/n)	// Q(K,n) is used in the flux
			w_bt[j] = Kp/(0.0934*lu) 	// Magnetic field (T)
			if (mode == 1)
				w_fl[j] = 1.431*10^14*Np*w_qk[j]*I_e 	// flux
				w_af[j] = 1.7441*10^14*Np^2*E_e^2*I_e*w_fk[j] 			// angular flux density
			elseif (mode == 2)
				w_fl[j] = 2.86*10^14*Np*I_e*Kp^2/(1+Kp^2)
				w_af[j] = 3.49*10^14*Np^2*E_e^2*I_e*(Kp/(1+Kp^2))^2 			// angular flux density
			endif
			w_br[j] = w_fl[j]/(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^12
			
			// additional codes
			w_la[j] = ((lu*10^-3/(2*gg^2))*(1+Kp^2/2)/n) // m
			w_sr[j] = 10^6*SQRT(2*(u_length/1000)*(hc/(1000*w_en[j])))/(4*pi)
			w_sd[j] = 10^6*SQRT((hc/(w_en[j]*1000))/(2*(u_length/1000))) 			// beam divergence
			w_cx[j] = (w_sr[j]*w_sd[j])/(SQRT(sigma_xr^2+w_sr[j]^2)*SQRT(sigma_xd^2+w_sd[j]^2)) // horizontal
			w_cy[j] = (w_sr[j]*w_sd[j])/(SQRT(sigma_yr^2+w_sr[j]^2)*SQRT(sigma_yd^2+w_sd[j]^2)) // vertical
			w_cf[j] = w_cx[j]*w_cy[j]
			w_eaf[j] = w_fl[j]*(w_sd[j]^2/(SQRT(w_sd[j]^2+sigma_xd^2)*SQRT(w_sd[j]^2+sigma_yd^2))) 			// eff. angular flux density
			w_ebr[j] = w_eaf[j]/(2*pi*SQRT(w_sr[j]^2+sigma_xr^2)*SQRT(w_sr[j]^2+sigma_yr^2))*10^6
			// https://doi.org/10.1103/PhysRevAccelBeams.20.064801
			w_emr[j] = w_la[j]/(4*pi)
			eta_x = 2*pi*beta_x/(u_length/1000)
			eta_y = 2*pi*beta_y/(u_length/1000)
			emi_x = sigma_xr*sigma_xd*10^-12
			emi_y = sigma_yr*sigma_yd*10^-12
			w_ebr[j] = w_fl[j]/(4*pi^2*SQRT(w_emr[j]^2+emi_x^2+w_emr[j]*emi_x*(eta_x+eta_x^-1))*SQRT(w_emr[j]^2+emi_y^2+w_emr[j]*emi_y*(eta_y+eta_y^-1)))*10^-12 // m rad -> mm mrad
			w_ebr[j] = w_ebr[j]/(sqrt(1+(5*n*Np*esp)^2))	// energy spread effect
			w_ebr[j] = w_ebr[j]*(exp(-(n*ph_err*pi/180)^2))	// energy spread effect
			w_efl[j] = w_ebr[j]*(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^-12
			// end codes
			
			if (i == 0)
				w_gk[j] = Kp*(Kp^6+(24/7)*Kp^4+4*Kp^2+(16/7))/((1+Kp^2)^(7/2)) //G(K) is used in the angular power density
			endif
			j = j + 1
		while(j < K_pnt)
		
		if (i == 0)
			en_0 = w_en[K_pnt-1]
			if (n_pnt == 1)
				en_1 = w_en[0]
			endif
		elseif (i == n_pnt-1)
			en_1 = w_en[0]
		endif
		SetScale/I	x K0,K,"K", w_fk, w_af, w_qk, w_bt, w_br, w_la, w_sr, w_sd, w_cx, w_cy, w_cf, w_eaf, w_ebr, w_emr, w_efl
		i = i + 1
	while(i < n_pnt)
	
	SetScale/I	x K0,K,"K", w_gk

	Variable pe_pnt = 1000, pe, pe_0 = 0.1, pe_1 = 100, d_pe = (pe_1 - pe_0)/(pe_pnt+1), B = K/(0.0934*lu) 	// Magnetic field (T)
	String ab, am, fb, fm, ub, um, bb, bm, brb, brm
	// BM specified by the B0 (field) or curverture (rho)
	// Variable B0 = 0.54, crt_bm = 3*hc*gg^3/4*pi*rho
	// BM approximated by the beam energy only: Excel Lightsource2018b.xlsx
	// a abritary factor of 5 is from SPring-8(8GeV,B0.68T,R39.3m,c28.9keV),SPS-II(3GeV,B0.87T,R11.5m,c5.2keV), SPS-1(1.2GrV,B1.4T,R2.78,c1.37keV)
	Variable rho_bm = (205.687*exp(-0.0056*(E_e-0.204)^2+0.31*(E_e-0.204))-196.846)/(2*pi*4.5), crt_bm = 3*hc*gg^3/(4*pi*rho_bm)/1000, B0 = crt_bm/(0.665*E_e^2)
	//printf "\r BM B: " + num2str(B0) + ", rho :" + num2str(rho_bm) + ", omega_c: " + num2str(crt_bm)
	Variable rho_mw = 3.335*E_e/B, crt_mw = (3*hc*gg^3)/(4*pi*rho_mw)/1000	// crt_mw = (0.665*E_e^2*B)
	//printf "\r MPW B: " + num2str(B) + ", rho: " + num2str(rho_mw) + ", omega_c: " + num2str(crt_mw)
	// https://www.jsac.or.jp/bunseki/pdf/bunseki2015/201501nyuumon.pdf
	en = w + "_en"
	ab = w + "_af_bm"
	am = w + "_af_mw"
	fb = w + "_fl_bm"
	fm = w + "_fl_mw"
	ub = w + "_ub"
	um = w + "_um"
	bb = w + "_bb"
	bm = w + "_bm"
	brb = w + "_br_bm"
	brm = w + "_br_mw"
	
	Make/D/N=(pe_pnt)/O $ab, $am, $en, $fb, $fm, $ub, $um, $bb, $bm, $brb, $brm
	Wave w_en = $en, w_ab = $ab, w_am = $am, w_fb = $fb, w_fm = $fm, w_ub = $ub, w_um = $um, w_bb = $bb, w_bm = $bm, w_brb = $brb, w_brm = $brm

	j = 0
	Do
		w_en[j] = pe_0 + d_pe*j
		w_ub[j] = w_en[j]/crt_bm	// omega/omega_c
		w_um[j] = w_en[j]/crt_mw	// https://www.cockcroft.ac.uk/wp-content/uploads/2014/12/Lecture-1.pdf
		w_bb[j] = Besselk(5/3,w_ub[j]) // Besselk is numerically integrated in AreaXY below
		w_bm[j] = Besselk(5/3,w_um[j])
		//w_fb[j] = 2.46*10^13*E_e*I_e*(w_ub[j])*AreaXY(w_ub, w_bb, w_ub[j], Inf)
		//w_fm[j] = 2.46*10^13*2*Np*E_e*I_e*(w_um[j])*AreaXY(w_um, w_bm, w_um[j], Inf)
		w_ab[j] = 1.33*10^13*E_e^2*I_e*w_ub[j]^2*BESSELK(2/3,w_ub[j]/2)^2
		w_am[j] = 1.33*10^13*2*Np*E_e^2*I_e*w_um[j]^2*BESSELK(2/3,w_um[j]/2)^2
		j = j + 1
	while(j<pe_pnt)
	
	j = 0
	Do
		w_fb[j] = 2.46*10^13*E_e*I_e*(w_ub[j])*AreaXY(w_ub, w_bb, w_ub[j], w_ub[pe_pnt-1])		// Inf or w_ub[pe_pnt-1]
		w_fm[j] = 2.46*10^13*2*Np*E_e*I_e*(w_um[j])*AreaXY(w_um, w_bm, w_um[j], w_um[pe_pnt-1])	// Inf or w_ub[pe_pnt-1]
		w_brb[j] = w_ab[j]/(2*pi*sigma_xr*sigma_yr)*10^6
		w_brm[j] = w_am[j]/(2*pi*sigma_xr*sigma_yr)*10^6
		j = j + 1
	while(j<pe_pnt)
	
	SetScale/I	x pe_0,pe_1,"Energy (keV)", w_en, w_ab, w_am, w_fb, w_fm, w_ub, w_um, w_bb, w_bm, w_brb, w_brm
	w_fm[pe_pnt-1] = nan	// the last point of integration is zero, then excluded
	
	String I_1d_plot
	Controlinfo/W=panelun setPlotOther
	//print V_Value
	if (V_Value == 2)
		I_1d_plot = "Flux"
	elseif  (V_Value == 3)
		I_1d_plot = "AFD"
	elseif  (V_Value == 4)
		I_1d_plot = "Bri"
	elseif  (V_Value == 5)
		I_1d_plot = "FKn"
	elseif  (V_Value == 6)
		I_1d_plot = "FKneV"
	elseif  (V_Value == 7)
		I_1d_plot = "QKn"
	elseif  (V_Value == 8)
		I_1d_plot = "GKn"
	elseif  (V_Value == 9)
		I_1d_plot = "Beam_size"
	elseif  (V_Value == 10)
		I_1d_plot = "Beam_div"
	elseif  (V_Value == 11)
		I_1d_plot = "CF_x"
	elseif  (V_Value == 12)
		I_1d_plot = "CF_y"
	elseif  (V_Value == 13)
		I_1d_plot = "CF"
	elseif  (V_Value == 14)
		I_1d_plot = "eb"
	elseif  (V_Value == 15)
		I_1d_plot = "ef"
	else
		return -1
	endif
	
	DoWindow $I_1d_plot
	if (V_flag == 1)
		TextBox/W=$I_1d_plot/C/N=$I_1d_plot/F=0/A=LT num2str(E_e)+" GeV, "+num2str(I_e*1000)+" mA, "+num2str(u_length/1000)+" m, period "+num2str(lu)+" mm, max K "+num2str(K)
	endif
end

Function calc_1d_plot()
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length
	NVAR n_har = root:un:n_har, K_0 = root:un:K_0, K_1 = root:un:K_1, K_t = root:un:K_t, K_pnt = root:un:K_pnt, lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_t = root:un:lu_t
	Variable i, j, n, n_pnt = (n_har+1)/2, Kp, d_K = (K_1 - K_0)/(K_pnt-1), lu = lu_1, en_0, en_1, mode, bm_plot
	String w = "I_1d", harstr, fl, af, fk, en, qk, gk, sr, sd, cx, cy, cf, br, eb, ef
	
	String I_1d_plot
	Controlinfo/W=panelun setPlotOther
	//print V_Value
	if (V_Value == 2)
		I_1d_plot = "Flux"
	elseif  (V_Value == 3)
		I_1d_plot = "AFD"
	elseif  (V_Value == 4)
		I_1d_plot = "Bri"
	elseif  (V_Value == 5)
		I_1d_plot = "FKn"
	elseif  (V_Value == 6)
		I_1d_plot = "FKneV"
	elseif  (V_Value == 7)
		I_1d_plot = "QKn"
	elseif  (V_Value == 8)
		I_1d_plot = "GKn"
	elseif  (V_Value == 9)
		I_1d_plot = "Beam_size"
	elseif  (V_Value == 10)
		I_1d_plot = "Beam_div"
	elseif  (V_Value == 11)
		I_1d_plot = "CF_x"
	elseif  (V_Value == 12)
		I_1d_plot = "CF_y"
	elseif  (V_Value == 13)
		I_1d_plot = "CF"
	elseif  (V_Value == 14)
		I_1d_plot = "eb"
	elseif  (V_Value == 15)
		I_1d_plot = "ef"
	else
		return -1
	endif
	
	Controlinfo/W=panelun setBMPlot
	bm_plot = V_Value
	
	DoWindow $I_1d_plot
	if (V_flag == 1)
		DoWindow/K $I_1d_plot
	endif
	
	Controlinfo/W=panelun setMode
	mode = V_Value
	if (mode == 2)
		n_pnt = 1
	endif
	
	gk = w + "_gk"
	if (stringmatch(I_1d_plot,"GKn")==1)
		Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $gk
		Label/W=$I_1d_plot left "G"
		SetAxis/W=$I_1d_plot left 0,1
	endif
	
	i = 0
	Do
		n = i*2+1
		harstr = num2str(n)
		en = w + "_en_n" + harstr
		fk = w + "_fk_n" + harstr
		qk = w + "_qk_n" + harstr
		fl = w + "_fl_n" + harstr
		af = w + "_af_n" + harstr
		br = w + "_br_n" + harstr
		sr = w + "_sr_n" + harstr
		sd = w + "_sd_n" + harstr
		cx = w + "_cx_n" + harstr
		cy = w + "_cy_n" + harstr
		cf = w + "_cf_n" + harstr
		eb = w + "_ebr_n" + harstr	// effective brilliance
		ef = w + "_efl_n" + harstr	// effective flux
		Wave w_en = $en
		
		if (i==0)
			if (stringmatch(I_1d_plot,"FKneV")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $fk vs $en
			elseif (stringmatch(I_1d_plot,"FKn")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $fk
			elseif (stringmatch(I_1d_plot,"QKn")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $qk
			elseif  (stringmatch(I_1d_plot,"GKn")==1)
				// skip
			elseif  (stringmatch(I_1d_plot,"Flux")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $fl vs $en
			elseif  (stringmatch(I_1d_plot,"AFD")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $af vs $en
			elseif  (stringmatch(I_1d_plot,"Bri")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $br vs $en
			elseif  (stringmatch(I_1d_plot,"Beam_size")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $sr vs $en
			elseif  (stringmatch(I_1d_plot,"Beam_div")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $sd vs $en
			elseif  (stringmatch(I_1d_plot,"CF_x")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $cx vs $en
			elseif  (stringmatch(I_1d_plot,"CF_y")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $cy vs $en
			elseif  (stringmatch(I_1d_plot,"CF")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $cf vs $en
			elseif  (stringmatch(I_1d_plot,"eb")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $eb vs $en
			elseif  (stringmatch(I_1d_plot,"ef")==1)
				Display/N=$I_1d_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize) $ef vs $en
			endif
		else
			if (stringmatch(I_1d_plot,"FKneV")==1)
				AppendToGraph/W=$I_1d_plot $fk vs $en
			elseif (stringmatch(I_1d_plot,"FKn")==1)
				AppendToGraph/W=$I_1d_plot $fk
			elseif (stringmatch(I_1d_plot,"QKn")==1)
				AppendToGraph/W=$I_1d_plot $qk
			elseif (stringmatch(I_1d_plot,"GKn")==1)
				// skip
			elseif (stringmatch(I_1d_plot,"Flux")==1)
				AppendToGraph/W=$I_1d_plot $fl vs $en
			elseif (stringmatch(I_1d_plot,"AFD")==1)
				AppendToGraph/W=$I_1d_plot $af vs $en
			elseif (stringmatch(I_1d_plot,"Bri")==1)
				AppendToGraph/W=$I_1d_plot $br vs $en
			elseif (stringmatch(I_1d_plot,"Beam_size")==1)
				AppendToGraph/W=$I_1d_plot $sr vs $en
			elseif (stringmatch(I_1d_plot,"Beam_div")==1)
				AppendToGraph/W=$I_1d_plot $sd vs $en
			elseif (stringmatch(I_1d_plot,"CF_x")==1)
				AppendToGraph/W=$I_1d_plot $cx vs $en
			elseif (stringmatch(I_1d_plot,"CF_y")==1)
				AppendToGraph/W=$I_1d_plot $cy vs $en
			elseif (stringmatch(I_1d_plot,"CF")==1)
				AppendToGraph/W=$I_1d_plot $cf vs $en
			elseif (stringmatch(I_1d_plot,"eb")==1)
				AppendToGraph/W=$I_1d_plot $eb vs $en
			elseif (stringmatch(I_1d_plot,"ef")==1)
				AppendToGraph/W=$I_1d_plot $ef vs $en
			endif
		endif
		if (stringmatch(I_1d_plot,"Flux")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $fl, numpnts($en), num2str(n)
		elseif (stringmatch(I_1d_plot,"AFD")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $af, numpnts($en), num2str(n)
		elseif (stringmatch(I_1d_plot,"Bri")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $br, numpnts($en), num2str(n)
		elseif (stringmatch(I_1d_plot,"FKneV")==1 || stringmatch(I_1d_plot,"FKn")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $fk, 1, num2str(n)
		elseif (stringmatch(I_1d_plot,"QKn")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $qk, K_t-0.1, num2str(n)
		elseif  (stringmatch(I_1d_plot,"GKn")==1)
				// skip
		elseif  (stringmatch(I_1d_plot,"Beam_size")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $sr, numpnts($en), num2str(n)
		elseif  (stringmatch(I_1d_plot,"Beam_div")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $sd, numpnts($en), num2str(n)
		elseif  (stringmatch(I_1d_plot,"CF_x")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $cx, numpnts($en), num2str(n)
		elseif  (stringmatch(I_1d_plot,"CF_y")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $cy, numpnts($en), num2str(n)
		elseif  (stringmatch(I_1d_plot,"CF")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $cf, numpnts($en), num2str(n)
		elseif (stringmatch(I_1d_plot,"eb")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $eb, numpnts($en), num2str(n)
		elseif (stringmatch(I_1d_plot,"ef")==1)
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $ef, numpnts($en), num2str(n)
		endif
		
		if (i == 0)
			en_0 = w_en[K_pnt-1]
			if (n_pnt == 1)
				en_1 = w_en[0]
			endif
		elseif (i == n_pnt-1)
			en_1 = w_en[0]
		endif
		
		i = i + 1
	while(i < n_pnt)
	
	ModifyGraph/W=$I_1d_plot mirror=2
	ModifyGraph/W=$I_1d_plot grid=1,tick(left)=3,tick(bottom)=2,minor=1,gridStyle=3,gridRGB=(48059,48059,48059)
	if (stringmatch(I_1d_plot,"Flux")==1 || stringmatch(I_1d_plot,"AFD")==1 || stringmatch(I_1d_plot,"Bri")==1 || stringmatch(I_1d_plot,"eb")==1 || stringmatch(I_1d_plot,"ef")==1)
		if (stringmatch(I_1d_plot,"Flux")==1)
			Label/W=$I_1d_plot left "Flux (ph/s/0.1%bw)"
			if (bm_plot == 1)
				AppendToGraph/W=$I_1d_plot $"I_1d_fl_bm" vs $"I_1d_en"
				AppendToGraph/W=$I_1d_plot $"I_1d_fl_mw" vs $"I_1d_en"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_fl_bm", 3, "BM (hor. mrad)"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_fl_mw", 10, "MPW (hor. mrad)"
			endif
		elseif (stringmatch(I_1d_plot,"AFD")==1)
			Label/W=$I_1d_plot left "Angular flux density (ph/s/mrad\S2\M/0.1%bw)"
			if (bm_plot == 1)
				AppendToGraph/W=$I_1d_plot $"I_1d_af_bm" vs $"I_1d_en"
				AppendToGraph/W=$I_1d_plot $"I_1d_af_mw" vs $"I_1d_en"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_af_bm", 3, "BM (hor. mrad)"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_af_mw", 10, "MPW (hor. mrad)"
			endif
		elseif (stringmatch(I_1d_plot,"Bri")==1)
			Label/W=$I_1d_plot left "Brilliance (ph/s/mm2/mrad\S2\M/0.1%bw)"
			if (bm_plot == 1)
				AppendToGraph/W=$I_1d_plot $"I_1d_br_bm" vs $"I_1d_en"
				AppendToGraph/W=$I_1d_plot $"I_1d_br_mw" vs $"I_1d_en"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_bm", 3, "BM (hor. mrad)"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_mw", 10, "MPW (hor. mrad)"
			endif
		elseif (stringmatch(I_1d_plot,"eb")==1)
			Label/W=$I_1d_plot left "Effective brilliance (ph/s/mm\S2\M/mrad\S2\M/0.1%bw)"
			if (bm_plot == 1)
				AppendToGraph/W=$I_1d_plot $"I_1d_br_bm" vs $"I_1d_en"
				AppendToGraph/W=$I_1d_plot $"I_1d_br_mw" vs $"I_1d_en"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_bm", 3, "BM (hor. mrad)"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_mw", 10, "MPW (hor. mrad)"
			endif
		elseif (stringmatch(I_1d_plot,"ef")==1)
			Label/W=$I_1d_plot left "Effective flux (ph/s/0.1%bw)"
			if (bm_plot == 1)
				AppendToGraph/W=$I_1d_plot $"I_1d_br_bm" vs $"I_1d_en"
				AppendToGraph/W=$I_1d_plot $"I_1d_br_mw" vs $"I_1d_en"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_bm", 3, "BM (hor. mrad)"
				Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=$I_1d_plot $"I_1d_br_mw", 10, "MPW (hor. mrad)"
			endif
		endif
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
		ModifyGraph/W=$I_1d_plot log=1
		SetAxis/W=$I_1d_plot left 1e+11,*
		//SetAxis/W=$I_1d_plot bottom *,100
		//SetAxis/W=$I_1d_plot bottom en_0,en_1
		
		// add edge position K, L3, M5, and need XAS_edges.txt loaded as a delimited text
		if (WaveExists($"Element")==1 && WaveExists($"K_x")==1 && WaveExists($"K_y")==1)
			AppendToGraph/R/W=$I_1d_plot $"K_y" vs $"K_x"
			ModifyGraph/W=$I_1d_plot mode(K_y)=3,rgb(K_y)=(34952,34952,34952),textMarker(K_y)={$"Element","default",0,0,5,0.00,0.00}
			ModifyGraph/W=$I_1d_plot tick(right)=3,noLabel(right)=1
		endif
		if (WaveExists($"Element")==1 && WaveExists($"L3_x")==1 && WaveExists($"L3_y")==1)
			AppendToGraph/R/W=$I_1d_plot $"L3_y" vs $"L3_x"
			ModifyGraph/W=$I_1d_plot mode(L3_y)=3,rgb(L3_y)=(34952,34952,34952),textMarker(L3_y)={$"Element","default",0,0,5,0.00,0.00}
		endif
		if (WaveExists($"Element")==1 && WaveExists($"M5_x")==1 && WaveExists($"M5_y")==1)
			AppendToGraph/R/W=$I_1d_plot $"M5_y" vs $"M5_x"
			ModifyGraph/W=$I_1d_plot mode(M5_y)=3,rgb(M5_y)=(34952,34952,34952),textMarker(M5_y)={$"Element","default",0,0,5,0.00,0.00}
		endif
		
	elseif (stringmatch(I_1d_plot,"FKneV")==1)
		Label/W=$I_1d_plot left "F(K,n)"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
		SetAxis/W=$I_1d_plot bottom en_0,en_1
	elseif (stringmatch(I_1d_plot,"FKn")==1 || stringmatch(I_1d_plot,"FKneV")==1)
		Label/W=$I_1d_plot left "F(K,n)"
	elseif (stringmatch(I_1d_plot,"QKn")==1)
		Label/W=$I_1d_plot left "Q"
	elseif (stringmatch(I_1d_plot,"Beam_size")==1)
		Label/W=$I_1d_plot left "Beam size (um)"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
	elseif (stringmatch(I_1d_plot,"Beam_div")==1)
		Label/W=$I_1d_plot left "Beam divergence (urad)"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
	elseif (stringmatch(I_1d_plot,"CF_x")==1)
		Label/W=$I_1d_plot left "Horizontal coherent fraction"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
	elseif (stringmatch(I_1d_plot,"CF_y")==1)
		Label/W=$I_1d_plot left "Vertical coherent fraction"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
	elseif (stringmatch(I_1d_plot,"CF")==1)
		Label/W=$I_1d_plot left "Coherent fraction"
		Label/W=$I_1d_plot bottom "Photon energy (keV)"
	endif
	
	setcolor()
	TextBox/W=$I_1d_plot/C/N=$I_1d_plot/F=0/A=LB num2str(E_e)+" GeV, "+num2str(I_e*1000)+" mA, "+num2str(u_length/1000)+" m, period "+num2str(lu_t)+" mm, max K "+num2str(K_t)
end

Function Gap_lu_K()
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, n_har = root:un:n_har
	NVAR lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt, K_0 = root:un:K_0, K_1 = root:un:K_1, K_pnt = root:un:K_pnt
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	
	String savedDF = GetDataFolder(1), gapstr
	Variable i = 0, j = 0, d_gap = (gap_1 - gap_0)/(gap_pnt-1), d_lu = (lu_1 - lu_0)/(lu_pnt-1), magnet_mode=1, gap, lu, gap_rng_0, gap_rng_1
	
	Controlinfo/W=panelun setType
	magnet_mode = V_Value
	
	Do 
		j = 0
		gap = gap_0+d_gap*i
		gapstr = num2str(gap)
		Make/D/N=(lu_pnt)/O $"Gap_lu_field_gap" + gapstr, $"Gap_lu_K_gap" + gapstr, $"Gap_lu" + gapstr
		Wave w_field = $"Gap_lu_field_gap" + gapstr, w_K = $"Gap_lu_K_gap" + gapstr, w_gap_lu = $"Gap_lu" + gapstr
		Make/D/N=(lu_pnt,gap_pnt)/O $"Gap_lu_field_gap", $"Gap_lu_K_gap", $"Gap_lu"
		Wave m_gap_lu_field = $"Gap_lu_field_gap", m_gap_lu_K_gap = $"Gap_lu_K_gap", m_gap_lu = $"Gap_lu"
		
		Do
			lu = lu_0+d_lu*j
			w_gap_lu[j] = gap/lu
			
			if (gap/lu > gap_lu_0 && gap/lu < gap_lu_1)
//				if (magnet_mode == 3)
//					w_field[j] = 2*Br*(sin(pi/M)/(pi/M))*exp(-pi*(gap/lu))*(1-exp(-2*pi*(h_lu_r)))
//				elseif (magnet_mode == 6)
//					w_field[j] = (0.28052+0.05798*lu-0.0009*lu^2+5.1E-6*lu^3)*exp(-pi*((gap/lu)-0.5))
//				else
//					w_field[j] = T_a*exp((gap/lu)*(T_b+T_c*(gap/lu)))
//				endif
				
				w_field[j] = calc_field(gap, lu)
				w_K[j] = 0.0934*w_field[j]*lu
			else
				w_field[j] = NaN
				w_K[j] = NaN
			endif
			
			m_gap_lu_field[j][i] = w_field[j]
			m_gap_lu_K_gap[j][i] = w_K[j]
			m_gap_lu[j][i] = w_gap_lu[j]
			j = j + 1
		while(j < lu_pnt)
		
		SetScale/I	x lu_0,lu_1,"Undulator period (mm)", w_field, w_K, w_gap_lu
		KillWaves/Z w_gap_lu
		i = i + 1
	while(i < gap_pnt)
	
	// K matrix in Field vs period plot
	Variable fld_0 = WaveMin($"Gap_lu_field_gap" + num2str(gap_1)), fld_1 = WaveMax($"Gap_lu_field_gap" + num2str(gap_0)), fld_pnt=100
	Variable d_fld = (fld_1 - fld_0)/(fld_pnt+1), fld, N, mode, hc = 1.2398*10^-6, gg=E_e/0.000511, pe
	Make/D/N=(lu_pnt,fld_pnt)/O $"Gap_lu_field_K", $"Gap_lu_field_fk", $"Gap_lu_field_fl", $"Gap_lu_field_af", $"Gap_lu_field_en", $"Gap_lu_field_mw"
	Wave m_gap_lu_field_K = $"Gap_lu_field_K", m_gap_lu_field_fk = $"Gap_lu_field_fk", m_gap_lu_field_fl = $"Gap_lu_field_fl", m_gap_lu_field_af = $"Gap_lu_field_af", m_gap_lu_field_en = $"Gap_lu_field_en", m_gap_lu_field_mw = $"Gap_lu_field_mw"
	
	//printf "\r Field min: " + num2str(fld_0) + ", max: "+num2str(fld_1)
	Controlinfo/W=panelun setMode
	mode = V_Value
	
	i=0
	Do
		j = 0
		fld = fld_0 + d_fld * i
		Do
			lu = lu_0+d_lu*j
			N = floor(u_length/lu)
			m_gap_lu_field_K[j][i] = 0.0934*fld*lu
			m_gap_lu_field_en[j][i] = ((10^-3)*(hc))/((lu*10^-3/(2*gg^2))*(1+m_gap_lu_field_K[j][i]^2/2))
			m_gap_lu_field_fk[j][i] = ((n_har*m_gap_lu_field_K[j][i])^2/((1+m_gap_lu_field_K[j][i]^2/2)^2))*(BESSELJ((n_har-1)/2,n_har*m_gap_lu_field_K[j][i]^2/(4*(1+m_gap_lu_field_K[j][i]^2/2)))-BESSELJ((n_har+1)/2,n_har*m_gap_lu_field_K[j][i]^2/(4*(1+m_gap_lu_field_K[j][i]^2/2))))^2
			if (mode == 1)
				m_gap_lu_field_fl[j][i] = 1.431*10^14*N*(1+m_gap_lu_field_K[j][i]^2/2)*(m_gap_lu_field_fk[j][i]/n_har)*I_e // it depends on fk formula
				m_gap_lu_field_af[j][i] = 1.7441*10^14*N^2*E_e^2*I_e*m_gap_lu_field_fk[j][i]
			elseif (mode == 2)
				m_gap_lu_field_fl[j][i] = 2.86*10^14*N*I_e*m_gap_lu_field_K[j][i]^2/(1+m_gap_lu_field_K[j][i]^2) // it depends on fk formula
				m_gap_lu_field_af[j][i] = 3.49*10^14*N^2*E_e^2*I_e*(m_gap_lu_field_K[j][i]/(1+m_gap_lu_field_K[j][i]^2))^2 
			endif
			// MPW AFD at 50 keV
			pe = 50
			m_gap_lu_field_mw[j][i] = 1.33*10^13*2*N*E_e^2*I_e*(pe/(0.665*E_e^2*fld))^2*BESSELK(2/3,(pe/(0.665*E_e^2*fld))/2)^2
			
			j = j + 1
		while(j<lu_pnt)
		i = i + 1
	while(i<fld_pnt)
	
	SetScale/I	x lu_0,lu_1,"Undulator period (mm)", m_gap_lu_field, m_gap_lu_K_gap, m_gap_lu, m_gap_lu_field_K, m_gap_lu_field_fk, m_gap_lu_field_fl, m_gap_lu_field_af, m_gap_lu_field_en, m_gap_lu_field_mw
	SetScale/I	y gap_0,gap_1,"Gap (mm)", m_gap_lu_field, m_gap_lu_K_gap, m_gap_lu
	SetScale/I  y fld_0, fld_1,"Field (T)", m_gap_lu_field_K, m_gap_lu_field_fk, m_gap_lu_field_fl, m_gap_lu_field_af, m_gap_lu_field_en, m_gap_lu_field_mw
	
	SetDataFolder savedDF
	DoWindow/F panelun
End

Function plot_field_lu()
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, lu_0 = root:un:lu_0, lu_1 = root:un:lu_1
	Variable i = 0, d_gap = (gap_1 - gap_0)/(gap_pnt-1), gap, lu = lu_1-(lu_1-lu_0)/10
	String gapstr, m_plot, Field_lu_plot = "Field_lu_plot", gap_list, gap_wave, Field_gap_plot = "Field_gap_plot", g_plot
	
	DoWindow $Field_lu_plot
	if (V_flag == 1)
		DoWindow/K $Field_lu_plot
	endif
	
	DoWindow $Field_gap_plot
	if (V_flag == 1)
		DoWindow/K $Field_gap_plot
	endif
	
	m_plot = "Gap_lu_field_K"		// plot matrix data: default: "Gap_lu_field_K"
									// can be "Gap_lu_field_mw", "Gap_lu_field_fl", "Gap_lu_field_af"
	
	// K contour in field vs period plot
	Display/N=$Field_lu_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize)
	AppendMatrixContour/W=$Field_lu_plot $m_plot
	ModifyContour/W=$Field_lu_plot $m_plot autoLevels={*,*,11}
	ModifyGraph/W=$Field_lu_plot nticks=5,manTick=0,manMinor(bottom)={0,0}
	ModifyGraph/W=$Field_lu_plot grid=1,tick=2,mirror=2,minor(left)=1,gridStyle=3,gridRGB=(34952,34952,34952)
	
	// Field vs period for each gap value
	Controlinfo/W=panelun setGapPlot
	if (V_Value == 1)		
		Do 
			gap = gap_0+d_gap*i
			gapstr = num2str(gap)
			AppendToGraph/W=$Field_lu_plot $"Gap_lu_field_gap" + gapstr
			ModifyGraph/W=$Field_lu_plot  lsize($"Gap_lu_field_gap" + gapstr)=1.5
			Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=Field_lu_plot $"Gap_lu_field_gap" + gapstr, lu, gapstr+" mm"
			i = i + 1
		while(i<gap_pnt)
		
		i =0
		gap_list = WaveList("Gap_lu_field_gap*", ";", "DIMS:1")
		print ItemsInList(gap_list, ";")
		Do
			gap_wave = StringFromList(i, gap_list, ";")
			KillWaves/Z $gap_wave
			i = i + 1
		while(i < ItemsInList(gap_list, ";"))
	endif
	
	ModifyGraph/W=$Field_lu_plot mirror=2
	ModifyGraph/W=$Field_lu_plot grid=1,tick(left)=3,tick(bottom)=2,minor=1,gridStyle=3,gridRGB=(48059,48059,48059)
	//Label/W=Field_lu_plot left "Field (T)"
	//Label/W=Field_lu_plot bottom "Undulator period (mm)"
	setcolor()
	TextBox/W=$Field_lu_plot/C/N=$Field_lu_plot/F=0/A=LT "K"	// default "K", "flux" or "AFD"
	
	DoWindow/F panelun
End

Function calc_field_lu_w()		// wiggler mode
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, pe_wigg = root:un:pe_wigg, max_power = root:un:max_power
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt
	NVAR T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c, fld_0 = root:un:fld_0, fld_1 = root:un:fld_1, fld_pnt = root:un:fld_pnt
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	NVAR sigma_xr = root:un:sigma_xr, sigma_yr = root:un:sigma_yr, sigma_xd = root:un:sigma_xd, sigma_yd = root:un:sigma_yd, ph_err = root:un:ph_err
	NVAR emi_x = root:un:emi_x, emi_y = root:un:emi_y, beta_x = root:un:beta_x, beta_y = root:un:beta_y , esp = root:un:esp
	Variable i = 0, j=0, d_gap = (gap_1 - gap_0)/(gap_pnt-1), gap, d_lu = (lu_1-lu_0)/(lu_pnt-1), lu, n_har, plot_type, magnet_mode, eta_x, eta_y
	String Period_field_plot = "Period_field_plot", m_plot, gapstr, g_plot, plot_add
	
	String savedDF = GetDataFolder(1)
	
	Controlinfo/W=panelun setPlotWigg
	if (V_Value == 1)
		plot_type = 1	// spectral flux E=Ec
	elseif (V_Value ==2)
		plot_type = 2	// Spectral central brightness
	elseif (V_Value ==3)
		plot_type = 3
	elseif (V_Value ==4)
		plot_type = 4
	elseif (V_Value ==5)
		plot_type = 5
	elseif (V_Value ==6)
		plot_type = 6
	endif
	//https://photon-science.desy.de/sites/site_photonscience/content/e62/e189219/e187240/e187241/e187242/infoboxContent187245/f3_eng.pdf
	
	//Variable fld_0 = 1, fld_1 = 3, fld_pnt=100
	Variable d_fld = (fld_1 - fld_0)/(fld_pnt+1), fld, N, hc = 1.2398*10^-6, gg=E_e/0.000511
	
	Make/D/N=(lu_pnt,fld_pnt)/O $"Flux_lu_field_K", $"Flux_lu_field_mw", $"Flux_lu_field_en", $"Flux_lu_field_fk", $"Flux_lu_field_pw", $"Flux_lu_field_ul", $"Flux_lu_field_n", $"Flux_lu_field_pa"
	Wave m_flux_lu_field_K = $"Flux_lu_field_K", m_flux_lu_field_mw = $"Flux_lu_field_mw", m_flux_lu_field_en = $"Flux_lu_field_en", m_flux_lu_field_fk = $"Flux_lu_field_fk", m_flux_lu_field_pw = $"Flux_lu_field_pw", m_flux_lu_field_ul = $"Flux_lu_field_ul", m_flux_lu_field_n = $"Flux_lu_field_n", m_flux_lu_field_pa = $"Flux_lu_field_pa"
	
	Make/D/N=(lu_pnt,fld_pnt)/O $"Flux_lu_field_ha", $"Flux_lu_field_ag", $"Flux_lu_field_ap", $"Flux_lu_field_fl", $"Flux_lu_field_ef", $"Flux_lu_field_em"
	Wave m_flux_lu_field_ha = $"Flux_lu_field_ha", m_flux_lu_field_ag = $"Flux_lu_field_ag", m_flux_lu_field_ap = $"Flux_lu_field_ap", m_flux_lu_field_fl = $"Flux_lu_field_fl", m_flux_lu_field_ef = $"Flux_lu_field_ef", m_flux_lu_field_em = $"Flux_lu_field_em"
	
	i=0
	Do
		j = 0
		lu = lu_0+d_lu*i
		Do
			fld = fld_0 + d_fld * j
			//N = (u_length/lu)	// use floor for practical application 
			m_flux_lu_field_K[i][j] = 0.0934*fld*lu	// K
			m_flux_lu_field_en[i][j] = ((10^-3)*(hc))/((lu*10^-3/(2*gg^2))*(1+m_flux_lu_field_K[i][j]^2/2))
			
			m_flux_lu_field_pw[i][j] = 0.633 * E_e^2 * fld^2 * 1 * I_e	// kW power per m
			m_flux_lu_field_pa[i][j] = 0.633 * E_e^2 * fld^2 * m_flux_lu_field_ul[i][j] * I_e	// kW for ID length
			
			if (plot_type <= 2)	
				m_flux_lu_field_ul[i][j] = max_power/m_flux_lu_field_pw[i][j]	// ID length (m)
				m_flux_lu_field_n[i][j] = (1000*m_flux_lu_field_ul[i][j]/lu)	// # periods: use floor for practical application 
			else
				m_flux_lu_field_ul[i][j] = u_length/1000
				m_flux_lu_field_n[i][j] = 1000*m_flux_lu_field_ul[i][j]/lu
			endif
			
			m_flux_lu_field_ap[i][j] = 10.84 * fld * (E_e^4) * I_e * m_flux_lu_field_n[i][j]/1000	// kW/mrad
			n_har = floor(pe_wigg/m_flux_lu_field_en[i][j])
			
			if (mod(n_har, 2) == 0)
				n_har = n_har - 1
			endif
			// sec 3.7, https://indico.ictp.it/event/a02011/contribution/1/material/0/0.pdf
			m_flux_lu_field_ag[i][j] = 1000*4*sqrt((1+m_flux_lu_field_K[i][j]^2/2)/(gg^2))	// angle mrad: a factor of 4 = 2 x 2 from both sides x2 and emission for each side x2
			//m_flux_lu_field_ag[i][j] = m_flux_lu_field_K[i][j]/gg
			m_flux_lu_field_ha[i][j] = n_har
			// undulator Fk
			m_flux_lu_field_fk[i][j] = ((n_har*m_flux_lu_field_K[i][j])^2/((1+m_flux_lu_field_K[i][j]^2/2)^2))*(BESSELJ((n_har-1)/2,n_har*m_flux_lu_field_K[i][j]^2/(4*(1+m_flux_lu_field_K[i][j]^2/2)))-BESSELJ((n_har+1)/2,n_har*m_flux_lu_field_K[i][j]^2/(4*(1+m_flux_lu_field_K[i][j]^2/2))))^2
			m_flux_lu_field_fl[i][j] = 1.431*10^14*m_flux_lu_field_n[i][j]*(1+m_flux_lu_field_K[i][j]^2/2)*(m_flux_lu_field_fk[i][j]/m_flux_lu_field_ha[i][j])*I_e 

			if (plot_type == 1)	// wiggler < max power per horizontal mrad
				m_flux_lu_field_mw[i][j] = 2.458*10^13*2*m_flux_lu_field_n[i][j]*E_e*I_e*(pe_wigg/(0.665*E_e^2*fld))*0.6522
			elseif (plot_type == 2)		// wiggler < max power mrad^2
				m_flux_lu_field_mw[i][j] = 1.325*10^13*2*m_flux_lu_field_n[i][j]*E_e^2*I_e*(pe_wigg/(0.665*E_e^2*fld))^2*(BESSELK(2/3,(pe_wigg/(2*0.665*E_e^2*fld))))^2
			elseif (plot_type == 3)	// wiggler at u_length mrad^2
				m_flux_lu_field_mw[i][j] = 1.325*10^13*2*m_flux_lu_field_n[i][j]*E_e^2*I_e*(pe_wigg/(0.665*E_e^2*fld))^2*(BESSELK(2/3,(pe_wigg/(2*0.665*E_e^2*fld))))^2
			elseif (plot_type == 4)	// undulator at u_length mrad^2
				m_flux_lu_field_mw[i][j] = 1.7441*10^14*m_flux_lu_field_n[i][j]^2*E_e^2*I_e*m_flux_lu_field_fk[i][j]
			elseif (plot_type == 5)	// undulator at u_length mrad^2
				m_flux_lu_field_mw[i][j] = m_flux_lu_field_fl[i][j]
			elseif (plot_type == 6)	// undulator at u_length mrad^2
				m_flux_lu_field_em[i][j] = ((lu*10^-3/(2*gg^2))*(1+m_flux_lu_field_K[i][j]^2/2)/m_flux_lu_field_ha[i][j])/(4*pi)
				eta_x = 2*pi*beta_x/(u_length/1000)
				eta_y = 2*pi*beta_y/(u_length/1000)
				emi_x = sigma_xr*sigma_xd*10^-12
				emi_y = sigma_yr*sigma_yd*10^-12
				m_flux_lu_field_mw[i][j] = m_flux_lu_field_fl[i][j]/(4*pi^2*SQRT(m_flux_lu_field_em[i][j]^2+emi_x^2+m_flux_lu_field_em[i][j]*emi_x*(eta_x+eta_x^-1))*SQRT(m_flux_lu_field_em[i][j]^2+emi_y^2+m_flux_lu_field_em[i][j]*emi_y*(eta_y+eta_y^-1)))*10^-12 // m rad -> mm mrad
				m_flux_lu_field_mw[i][j] = m_flux_lu_field_mw[i][j]/(sqrt(1+(5*m_flux_lu_field_ha[i][j]*m_flux_lu_field_n[i][j]*esp)^2))	// energy spread effect
				m_flux_lu_field_mw[i][j] = m_flux_lu_field_mw[i][j]*(exp(-(m_flux_lu_field_ha[i][j]*ph_err*pi/180)^2))	// energy spread effect
				m_flux_lu_field_ef[i][j] = m_flux_lu_field_mw[i][j]*(4*pi^2*sigma_xr*sigma_yr*sigma_xd*sigma_yd)*10^-12
				m_flux_lu_field_mw[i][j] = m_flux_lu_field_ef[i][j]
			endif
			
			j = j + 1
		while(j<fld_pnt)
		i = i + 1
	while(i<lu_pnt)
	
	SetScale/I	x lu_0,lu_1,"ID period (mm)", m_flux_lu_field_K, m_flux_lu_field_mw, m_flux_lu_field_ul, m_flux_lu_field_n, m_flux_lu_field_pw, m_flux_lu_field_pa, m_flux_lu_field_ha, m_flux_lu_field_en, m_flux_lu_field_ag, m_flux_lu_field_ap, m_flux_lu_field_fl, m_flux_lu_field_ef
	SetScale/I  y fld_0, fld_1,"Field (T)", m_flux_lu_field_K, m_flux_lu_field_mw, m_flux_lu_field_ul, m_flux_lu_field_n, m_flux_lu_field_pw, m_flux_lu_field_pa, m_flux_lu_field_ha, m_flux_lu_field_en, m_flux_lu_field_ag, m_flux_lu_field_ap, m_flux_lu_field_fl, m_flux_lu_field_ef

	Controlinfo/W=panelun setType
	magnet_mode = V_Value

	i=0
	Do
		j = 0
		gap = gap_0 + d_gap * i
		gapstr = num2str(gap)
		Make/D/N=(lu_pnt)/O $"Flux_lu_field" + gapstr
		Wave m_flux_lu_field = $"Flux_lu_field" + gapstr
		
		Do
			lu = lu_0 + d_lu * j
			m_flux_lu_field[j] = calc_field(gap, lu)
			j = j + 1
		while(j<lu_pnt)
		
		SetScale/I x lu_0,lu_1,"ID period (mm)", m_flux_lu_field
		i = i + 1
	while(i<gap_pnt)
		
	SetDataFolder savedDF
end

Function plot_field_lu_w()
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	NVAR E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length, pe_wigg = root:un:pe_wigg, max_power = root:un:max_power
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, lu_0 = root:un:lu_0, lu_1 = root:un:lu_1, lu_pnt = root:un:lu_pnt
	NVAR fld_0 = root:un:fld_0, fld_1 = root:un:fld_1, fld_pnt = root:un:fld_pnt, iplot=root:un:iplot
	
	Variable i = 0, j=0, d_gap = (gap_1 - gap_0)/(gap_pnt-1), gap, d_lu = (lu_1-lu_0)/(lu_pnt-1), lu, n_har, plot_type, magnet_mode, eta_x, eta_y
	String Period_field_plot = "Period_field_plot", m_plot, gapstr, g_plot, plot_add
	
	String savedDF = GetDataFolder(1)
	
	DoWindow $Period_field_plot
	if (V_flag == 1)
		DoWindow/K $Period_field_plot
	endif
	
	Controlinfo/W=panelun setPlotWigg
	if (V_Value == 1)
		plot_type = 1	// spectral flux E=Ec
	elseif (V_Value ==2)
		plot_type = 2	// Spectral central brightness
	elseif (V_Value ==3)
		plot_type = 3
	elseif (V_Value ==4)
		plot_type = 4
	elseif (V_Value ==5)
		plot_type = 5
	elseif (V_Value ==6)
		plot_type = 6
	endif
	
	m_plot = "Flux_lu_field_mw"
	
	Display/N=$Period_field_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize)
	AppendMatrixContour/W=$Period_field_plot $m_plot
	ModifyContour/W=$Period_field_plot $m_plot autoLevels={*,*,11}
	ModifyGraph/W=$Period_field_plot nticks=5,manTick=0,manMinor(bottom)={0,0}
	ModifyGraph/W=$Period_field_plot grid=1,tick=2,mirror=2,minor(left)=1,gridStyle=3,gridRGB=(34952,34952,34952)
	// append image
	Controlinfo/W=panelun setimgplot
	if (V_Value == 1)
		AppendImage/W=$Period_field_plot $m_plot
		ModifyImage/W=$Period_field_plot $m_plot ctab={*, *, Rainbow, 0 }
	endif

	//setcolor()
	if (plot_type == 1)	// wiggler < max power
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Spectral Flux density (ph/s/mrad/0.1%bw) limited by "+num2str(max_power)+" kW at "+num2str(pe_wigg)+" keV"	
	elseif (plot_type == 2)	// wiggler < max power
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Angular Flux density (ph/s/mrad\S2\M/0.1%bw) limited by "+num2str(max_power)+" kW at "+num2str(pe_wigg)+" keV"
	elseif (plot_type == 3)	// wiggler at u_length
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Angular Flux density (ph/s/mrad\S2\M/0.1%bw) at "+num2str(u_length)+" mm at "+num2str(pe_wigg)+" keV in Wiggler"
	elseif (plot_type == 4)	// undulator at u_length
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Angular Flux density (ph/s/mrad\S2\M/0.1%bw) at "+num2str(u_length)+" mm at "+num2str(pe_wigg)+" keV in Undulator"
	elseif (plot_type == 5)	// undulator at u_length
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Flux (ph/s/0.1%bw) at "+num2str(u_length)+" mm at "+num2str(pe_wigg)+" keV in Undulator"
	elseif (plot_type == 6)	// undulator at u_length
		TextBox/W=$Period_field_plot/C/N=$Period_field_plot/F=0/A=LT "Effective Flux (ph/s/0.1%bw) at "+num2str(u_length)+" mm at "+num2str(pe_wigg)+" keV in Undulator"
	endif
	SetAxis/W=Period_field_plot left fld_0,fld_1
	SetAxis/W=Period_field_plot bottom lu_0,lu_1
	
	i=0
	Do
		gap = gap_0 + d_gap * i
		gapstr = num2str(gap)
		g_plot = "Flux_lu_field" + gapstr
		AppendToGraph/W=$Period_field_plot $g_plot
		ModifyGraph/W=$Period_field_plot lsize($g_plot)=1.5
		Tag/A=RT/B=0/F=0/I=0/L=0/Z=0/W=Period_field_plot/X=1/y=1 $g_plot, lu_1, gapstr+" mm"
		i = i + 1
	while(i<gap_pnt)
	
	setcolor()
	
	Controlinfo/W=panelun setAddWigg
	if (V_Value == 1)
		plot_add = "Flux_lu_field_ag"	// angle
	elseif (V_Value == 2)
		plot_add = "Flux_lu_field_ha"	// harmonics
	elseif (V_Value == 3)
		plot_add = "Flux_lu_field_K"	// K
	elseif (V_Value == 4)	
		plot_add = "Flux_lu_field_n"	// # periods
	elseif (V_Value == 5)
		plot_add = "Flux_lu_field_pw"	// kW power per 1 m
	elseif (V_Value == 6)
		plot_add = "Flux_lu_field_pa"	// kW power total
	elseif (V_Value == 7)
		plot_add = "Flux_lu_field_ul"	// total length
	endif
	
	AppendMatrixContour/W=$Period_field_plot $plot_add
	ModifyContour/W=$Period_field_plot $plot_add autoLevels={*,*,6}
	ModifyContour/W=$Period_field_plot $plot_add rgbLines=(43690,43690,43690), labelFStyle=2
	
	If (stringmatch(plot_add,"Flux_lu_field_ha")==1)
		ModifyContour $plot_add manLevels={1,2,21}
	endif
		
	SetDataFolder savedDF
	DoWindow/F panelun
End

Function phaseError()
	NVAR winpos = root:un:winpos, winsize = root:un:winsize, w_width = root:un:w_width, w_height = root:un:w_height
	Variable i, j, err, n
	Variable n_0 = 1, n_1 = 15, err_deg_0 = 0, err_deg_1 = 20, d_err_deg = 0.01
	// phase error in equation based on the radian unit
	Variable err_0 = err_deg_0*pi/180, d_err = d_err_deg*pi/180
	Variable n_pnt = (n_1-n_0+2)/2, err_pnt = (err_deg_1 - err_deg_0)/d_err_deg + 1
	String Phase_error_plot = "Phase_error_plot"
	
	Make/D/N=(n_pnt,err_pnt)/O I_n_err
	i = 0
	Do
		j = 0
		n = n_0+2*i
		Do
			err = err_0+d_err*j
			I_n_err[i][j] = exp(-(n*err)^2)
			j = j + 1
		while(j < err_pnt)
		i = i + 1
	while(i < n_pnt)
	
	SetScale/P	x n_0,2,"Harmonic number", I_n_err
	SetScale/I	y err_deg_0,err_deg_1,"Phase error (º)", I_n_err
	
	DoWindow $Phase_error_plot
	if (V_flag == 1)
		DoWindow/F $Phase_error_plot
	else
		Display/N=$Phase_error_plot/W=(winpos+w_width/winsize+10, 10, winpos+2*w_width/winsize, 10+w_height/winsize)
		AppendMatrixContour/W=$Phase_error_plot I_n_err
		ModifyContour/W=$Phase_error_plot I_n_err autoLevels={*,*,11}
		ModifyGraph/W=$Phase_error_plot nticks=5,manTick(bottom)={1,2,0,0},manMinor(bottom)={0,0}
		ModifyGraph/W=$Phase_error_plot grid=1,tick=2,mirror=2,minor(left)=1,gridStyle=3,gridRGB=(34952,34952,34952)
		SetAxis/W=Phase_error_plot left err_deg_0,err_deg_1
		TextBox/W=$Phase_error_plot/C/N=$Phase_error_plot/F=0/A=LT "I/I0"
	endif
end

Function set_E_e(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR E_e = root:un:E_e
	K_lu_energy()
	Gap_lu_K()
	
	NVAR lu_t = root:un:lu_t, K_t = root:un:K_t
	calc_1d(lu_t, K_t)
end

Function set_I_e(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR I_e = root:un:I_e
	K_lu_energy()
	Gap_lu_K()
	
	NVAR lu_t = root:un:lu_t, K_t = root:un:K_t
	calc_1d(lu_t, K_t)
end

Function set_u_length(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR u_length = root:un:u_length
	K_lu_energy()
	Gap_lu_K()
	
	NVAR lu_t = root:un:lu_t, K_t = root:un:K_t
	calc_1d(lu_t, K_t)
end

Function set_n_har(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR n_har = root:un:n_har
	K_lu_energy()
	Gap_lu_K()
	NVAR lu_t = root:un:lu_t, K_t = root:un:K_t
	calc_1d(lu_t, K_t)
	calc_1d_plot()
end

Function set_lu_0(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR lu_0 = root:un:lu_0
	K_lu_energy()
	Gap_lu_K()
end

Function set_lu_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR lu_1 = root:un:lu_1
	K_lu_energy()
	Gap_lu_K()
end

Function set_lu_pnt(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR lu_pnt = root:un:lu_pnt
	K_lu_energy()
	Gap_lu_K()
end

Function set_K_0(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_0 = root:un:K_0
	K_lu_energy()
	Gap_lu_K()
end

Function set_K_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_1 = root:un:K_1
	K_lu_energy()
	Gap_lu_K()
end

Function set_K_pnt(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_pnt = root:un:K_pnt
	K_lu_energy()
	Gap_lu_K()
end

Function set_E_x(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR emi_x = root:un:emi_x
	K_lu_energy()
end

Function set_E_y(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR emi_y = root:un:emi_y
	K_lu_energy()
end

Function set_B_x(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR beta_x = root:un:beta_x
	K_lu_energy()
end

Function set_B_y(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR beta_y = root:un:beta_y
	K_lu_energy()
end

Function set_S_xr(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR sigma_xr = root:un:sigma_xr, sigma_xd = root:un:sigma_xd, emi_x = root:un:emi_x, emi_y = root:un:emi_y, coupling = root:un:coupling
	emi_x = sigma_xr * sigma_xd *10^-12
	coupling = emi_y/emi_x
	printf "%.2e\r", emi_x
	printf "%.2e\r", emi_y
	K_lu_energy()
end

Function set_S_yr(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR sigma_yr = root:un:sigma_yr, sigma_yd = root:un:sigma_yd, emi_x = root:un:emi_x, emi_y = root:un:emi_y, coupling = root:un:coupling
	emi_y = sigma_yr * sigma_yd *10^-12
	coupling = emi_y/emi_x
	K_lu_energy()
end

Function set_S_xd(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR sigma_xd = root:un:sigma_xd, sigma_xr = root:un:sigma_xr, emi_x = root:un:emi_x, emi_y = root:un:emi_y, coupling = root:un:coupling
	emi_x = sigma_xr * sigma_xd *10^-12
	coupling = emi_y/emi_x
	K_lu_energy()
end

Function set_S_yd(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR sigma_yd = root:un:sigma_yd, sigma_yr = root:un:sigma_yr, emi_x = root:un:emi_x, emi_y = root:un:emi_y, coupling = root:un:coupling
	emi_y = sigma_yr * sigma_yd *10^-12
	coupling = emi_y/emi_x
	K_lu_energy()
end

Function set_esp(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR esp = root:un:esp
	K_lu_energy()
end

Function set_cou(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR coupling = root:un:coupling, emi_x = root:un:emi_x, emi_y = root:un:emi_y
	coupling = emi_y/emi_x
	K_lu_energy()
end

Function set_Type_mag(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR T_a = root:un:T_a
	NVAR T_b = root:un:T_b
	NVAR T_c = root:un:T_c
	
	if (popNum == 1)
		NVAR PPM_a = root:un:PPM_a
		NVAR PPM_b = root:un:PPM_b
		NVAR PPM_c = root:un:PPM_c
		T_a = PPM_a
		T_b = PPM_b
		T_c = PPM_c
	elseif (popNum == 2)
		NVAR HYB_a = root:un:HYB_a
		NVAR HYB_b = root:un:HYB_b
		NVAR HYB_c = root:un:HYB_c
		T_a = HYB_a
		T_b = HYB_b
		T_c = HYB_c
	elseif (popNum == 3)
		NVAR HFe_a = root:un:HFe_a
		NVAR HFe_b = root:un:HFe_b
		NVAR HFe_c = root:un:HFe_c
		T_a = HFe_a
		T_b = HFe_b
		T_c = HFe_c
	elseif (popNum == 4)
		NVAR HCo_a = root:un:HCo_a
		NVAR HCo_b = root:un:HCo_b
		NVAR HCo_c = root:un:HCo_c
		T_a = HCo_a
		T_b = HCo_b
		T_c = HCo_c
	elseif (popNum == 5)
		NVAR CPM_a = root:un:CPM_a
		NVAR CPM_b = root:un:CPM_b
		NVAR CPM_c = root:un:CPM_c
		T_a = CPM_a
		T_b = CPM_b
		T_c = CPM_c
	elseif (popNum == 6)
		NVAR CPH_a = root:un:CPH_a
		NVAR CPH_b = root:un:CPH_b
		NVAR CPH_c = root:un:CPH_c
		T_a = CPH_a
		T_b = CPH_b
		T_c = CPH_c
	elseif (popNum == 7)
		NVAR SCM_a = root:un:SCM_a
		NVAR SCM_b = root:un:SCM_b
		NVAR SCM_c = root:un:SCM_c
		T_a = SCM_a
		T_b = SCM_b
		T_c = SCM_c
	elseif (popNum == 7)
		// SCM(Kim)
	elseif (popNum == 8)
		// User define
	elseif (popNum == 9)
		// PPM(Br, M, h)
	endif
	
	Gap_lu_K()
	Plot_field_lu()
End

Function set_T_a(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR T_a = root:un:T_a
	Gap_lu_K()
	Plot_field_lu()
end

Function set_T_b(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR T_b = root:un:T_b
	Gap_lu_K()
	Plot_field_lu()
end

Function set_T_c(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR T_c = root:un:T_c
	Gap_lu_K()
	Plot_field_lu()
end

Function set_Br(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR Br = root:un:Br
	Gap_lu_K()
	Plot_field_lu()
end

Function set_M(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR M = root:un:M
	Gap_lu_K()
	Plot_field_lu()
end

Function set_h_lu_r(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR h_lu_r = root:un:h_lu_r
	Gap_lu_K()
	Plot_field_lu()
end

Function set_gap_0(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR gap_0 = root:un:gap_0
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
end

Function set_gap_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR gap_1 = root:un:gap_1
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
end

Function set_gap_pnt(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR gap_pnt = root:un:gap_pnt
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
end

Function set_mode(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	K_lu_energy()
	Gap_lu_K()
	Other_plots()
End

Function set_plot_type(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
End

Function set_data_type(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	K_lu_energy()
	Gap_lu_K()
	B_un_plot()
End

Function set_color_type(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
End

Function set_color_rev(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR crev = root:un:crev
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
End

Function set_gap_plot(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gplot = root:un:gplot
	Gap_lu_K()
	K_lu_energy()
	B_un_plot()
End

Function set_color_gap(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
End

Function set_plot_gap(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	K_lu_energy()
	Gap_lu_K()
	Gap_lu_plot()
End

Function set_plot_other(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	K_lu_energy()
	Gap_lu_K()
	Other_plots()
End

Function set_BM_plot(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR xplot = root:un:xplot
	K_lu_energy()
	Gap_lu_K()
	Other_plots()
End

Function luscaleproc(name, value, event)
	String name	// name of this slider control
	Variable value	// value of slider
	Variable event	// bit field: bit 0: value set; 1: mouse down, 
				//   2: mouse up, 3: mouse moved
	NVAR K_t = root:un:K_t, lu_t = root:un:lu_t, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	SVAR lu_str = root:un:lu_str, K_str = root:un:K_str
	lu_str = "Period "+num2str(value)
	Variable field, gap = gap_0	// gap at the minimum specified in the initial gap range.
	String plot_type
	
	Controlinfo/W=panelun setType
	
	if (gap/lu_t > gap_lu_0 && gap/lu_t < gap_lu_1)
		field = calc_field(gap, lu_t)
		K_t = 0.0934*field*lu_t
	else
		field = NaN
		K_t = NaN
	endif
			
	calc_1d(lu_t, K_t)	
	K_str = "max K "+num2str(K_t)
	
	Controlinfo/W=panelun setPlotType
	if (V_Value == 1)
		plot_type = "c"
	else
		plot_type = "i"
	endif
	
	Controlinfo/W=panelun setGapPlot
	if (V_Value == 1)
		String topGraphName = "Un_plot_" + plot_type + "_" + targetName(1)
		DoWindow $topGraphName
		if (V_flag == 1)
			Cursor/S=2/C=(1,16019,65535)/W=$topGraphName A, $"Gap_lu_K_gap"+num2str(gap_0), lu_t
		endif
	endif
End

Function Kscaleproc(name, value, event)
	String name	// name of this slider control
	Variable value	// value of slider
	Variable event	// bit field: bit 0: value set; 1: mouse down, 
				//   2: mouse up, 3: mouse moved
	NVAR K_t = root:un:K_t, lu_t = root:un:lu_t, K_max = root:un:K_max, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	SVAR lu_str = root:un:lu_str, K_str = root:un:K_str
	K_str = "max K "+num2str(value)
	Variable field, gap = gap_0	// gap at the minimum specified in the initial gap range.
	
	calc_1d(lu_t, value)
End

Function set_lu_scale(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_t = root:un:K_t, lu_t = root:un:lu_t, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	SVAR lu_str = root:un:lu_str, K_str = root:un:K_str
	lu_str = "Period "+num2str(varNum)
	Variable field, gap = gap_0	// gap at the minimum specified in the initial gap range.
	String plot_type
	
	Controlinfo/W=panelun setType
	
	if (gap/lu_t > gap_lu_0 && gap/lu_t < gap_lu_1)
		field = calc_field(gap, lu_t)
		K_t = 0.0934*field*lu_t
	else
		field = NaN
		K_t = NaN
	endif
			
	calc_1d(varNum, K_t)	
	K_str = "max K "+num2str(K_t)
	
	Controlinfo/W=panelun setPlotType
	if (V_Value == 1)
		plot_type = "c"
	else
		plot_type = "i"
	endif
	
	Controlinfo/W=panelun setGapPlot
	if (V_Value == 1)
		String topGraphName = "Un_plot_" + plot_type + "_" + targetName(1)
		DoWindow $topGraphName
		if (V_flag == 1)
			Cursor/S=2/C=(1,16019,65535)/W=$topGraphName A, $"Gap_lu_K_gap"+num2str(gap_0), lu_t
		endif
	endif
	
end

Function set_K_scale(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_t = root:un:K_t, lu_t = root:un:lu_t, K_max = root:un:K_max, E_e = root:un:E_e, I_e = root:un:I_e, u_length = root:un:u_length
	NVAR gap_0 = root:un:gap_0, gap_1 = root:un:gap_1, gap_pnt = root:un:gap_pnt, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	SVAR lu_str = root:un:lu_str, K_str = root:un:K_str
	K_str = "max K "+num2str(varNum)
	Variable field, gap = gap_0	// gap at the minimum specified in the initial gap range.
	
	calc_1d(lu_t, varNum)
end


Function set_ph_err(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR K_t = root:un:K_t, lu_t = root:un:lu_t
	calc_1d(lu_t, K_t)
end

Function set_pe_wigg(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR pe_wigg = root:un:pe_wigg
	calc_field_lu_w()
end

Function set_max_power(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR max_power = root:un:max_power
	calc_field_lu_w()
end

Function set_plot_wigg(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	calc_field_lu_w()
	plot_field_lu_w()
End

Function set_add_wigg(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	calc_field_lu_w()
	plot_field_lu_w()
End

Function set_fld_0(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR fld_0 = root:un:fld_0
	calc_field_lu_w()
end

Function set_fld_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR fld_1 = root:un:fld_1
	calc_field_lu_w()
end

Function set_fld_pnt(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	NVAR fld_pnt = root:un:fld_pnt
	calc_field_lu_w()
end

Function set_img_plot(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR iplot = root:un:iplot
	calc_field_lu_w()
	plot_field_lu_w()
End

Function calc_field(gap, lu)
	Variable gap, lu
	NVAR gap_lu_0 = root:un:gap_lu_0, gap_lu_1 = root:un:gap_lu_1
	NVAR Br = root:un:Br, M = root:un:M, h_lu_r = root:un:h_lu_r, T_a = root:un:T_a, T_b = root:un:T_b, T_c = root:un:T_c
	Variable field
	
	if (gap/lu > gap_lu_0 && gap/lu < gap_lu_1)
		Controlinfo/W=panelun setType
		if (V_Value == 10)
			field = 2*Br*(sin(pi/M)/(pi/M))*exp(-pi*(gap/lu))*(1-exp(-2*pi*(h_lu_r)))
		elseif (V_Value == 8)
			field = (0.28052+0.05798*lu-0.0009*lu^2+5.1E-6*lu^3)*exp(-pi*((gap/lu)-0.5))
		else
			field = T_a*exp((gap/lu)*(T_b+T_c*(gap/lu)))
		endif
	else
		field = NaN
	endif
	
	return field
End

function setcolor0()
    string trl=tracenamelist("",";",1), item
    variable items=itemsinlist(trl), i
    variable ink=103/(items-1)
    colortab2wave yellowHot256
    wave/i/u M_colors
    for(i=0;i<items;i+=1)
        item=stringfromlist(i,trl)
        ModifyGraph rgb($item)=(M_colors[140+i*ink][0],M_colors[140+i*ink][1],M_colors[140+i*ink][2])
    endfor
    killwaves/z M_colors
end

function setcolor()
    string trl=tracenamelist("",";",1), item
    variable items=itemsinlist(trl), i
    variable r, g, b
    
    for(i=0;i<items;i+=1)
        item=stringfromlist(i,trl)
        if (mod(i,10)==0)
        	r=0
        	g=16019
        	b=65535
        elseif (mod(i,10)==1)
        	r=52428
        	g=34958
        	b=1
        elseif (mod(i,10)==2)
        	r=1
        	g=52428
        	b=1
        elseif (mod(i,10)==3)
        	r=39321
        	g=39319
        	b=1
        elseif (mod(i,10)==4)
        	r=29524
        	g=1
        	b=58982
        elseif (mod(i,10)==5)
        	r=1
        	g=34817
        	b=52428
        elseif (mod(i,10)==6)
        	r=39321
        	g=1
        	g=15729
        elseif (mod(i,10)==7)
        	r=52428
        	g=4958
        	b=1
        elseif (mod(i,10)==8)
        	r=1
        	g=39321
        	b=19939
        elseif (mod(i,10)==9)
        	r=1
        	g=34817
        	b=52428
        else
        	r=0
        	g=0
        	b=65535
        endif
        ModifyGraph rgb($item)=(r,g,b)
    endfor
end

