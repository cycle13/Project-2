 ;;;;;
 function get_season(data,season)
 begin
     vint_beta_fi_win = month_to_season(data(:,{1000:100},{-40:40}), season)
    vint_beta_fi_win_clm = dim_avg_n_Wrap(vint_beta_fi_win, 0)
    return vint_beta_fi_win_clm
end

  begin 
	fils1  =  "/home/ys17-19/lsh/data/era/era_pre_global.nc"
    ; fils1  =  "/home/ys17-19/lsh/data/wc-result/msf_F_1850-PDAY-rmpacific_197912-201212.nc"
    
	f1  =  addfile(fils1, "r")
	timestart = 197901
	timeend = 201612
	date  =  cd_calendar(f1->time, 1)
	timeind  =  ind(date.le.timeend.and.date.ge.timestart)

	startyear_r = str_split_by_length(timestart, 4)  ;; 将时间string分解成年和月
	endyear_r = str_split_by_length(timeend, 4 )

	startyear = stringtoint(startyear_r(0))
	endyear = stringtoint(endyear_r(0))

	v  =  short2flt(f1->v(timeind,::-1,:,:))

	level = f1->level(::-1)
    ; print(level)
   
    ;; v avg 
      v_a = dim_avg_n_Wrap(v , 3) ;;;time,level,lat
    ;;

    ;;;积分
    level2 = level
    level2(0:dimsizes(level)-2) = level(1:)
    level2(dimsizes(level)-1) = 0
    dp = level - level2
 
    v_2 = v_a

    v_2(:,0:dimsizes(v_a&level)-2,:) = v_a(:,1:,:)
    v_2(:,dimsizes(v_a&level)-1,:) = 0
    v_a = (/(v_a + v_2)*0.5/)
    printVarSummary(v_a)
  

    ;;;;


;  ;;; 积分
      vint = v_a
; 	do i=0,dimsizes(level)-1
       
;         dp_new = conform_dims(dimsizes(v_a(:,i:,:)), dp(i:dimsizes(level2)-1), 1)
;         print(dp)
;         ; exit()
;         printVarSummary(dp_new)
;         vint(:,i,:)= dim_sum_n(v_a(:,i:,:)*dp_new,1)
;         ; delete(dp)
;         delete(dp_new)
;         ; delete(level2)
; 	end do 
;     ; vint(:,dimsizes(level)-1,:) = 50*ud_new(:,dimsizes(level)-1,:)
    
    a = 6371000
    g = 9.8
    pi = get_pi("double")
    dfi = pi
    cosfi = cos(v_a&latitude/180.0)
    ; print(cosfi)
    cosfi_new = conform_dims(dimsizes(vint), cosfi, 2)

  

;     fi = v_a
; 	fi := (/((2*a*dfi*cosfi_new)/g)*vint*100/)
;     fi = (/fi/10^10/)

;     copy_VarCoords(v_a, fi)
; 	delete(vint)
;     printVarSummary(fi)
;     fi_clm = dim_avg_n_Wrap(fi(:,{1000:100},{-30:30}), 0)
;     printVarSummary(fi_clm)

;     fi_win = month_to_season(fi(:,{1000:100},{-30:30}), "DJF")
;     fi_win_clm = dim_avg_n_Wrap(fi_win, 0)
; ;;;

;;; vibeta(p, x, linlog, psfc, pbot, ptop)积分
   
   vint_beta = v_a
   psfc = v_a(:,1,:)
   psfc = 1013.0
   
   do i = 0,dimsizes(level) -1
    vint_beta(:,i,:)  = (/vibeta( level, v_a(time|:,latitude|:,level|:), 1, psfc, level(i), 0)/)
  end do

    vint_beta_fi = v_a
    vint_beta_fi := (/((2*a*dfi*cosfi_new)/g)*vint_beta*100/)
    vint_beta_fi = (/vint_beta_fi/10^10/)
   copy_VarCoords(v_a, vint_beta_fi)
   vint_beta_clm = dim_avg_n_Wrap(vint_beta_fi(:,{1000:100},{-30:30}), 0)


    vint_beta_fi_win = month_to_season(vint_beta_fi(:,{1000:100},{-30:30}), "DJF")
    vint_beta_fi_win_clm = dim_avg_n_Wrap(vint_beta_fi_win, 0)
;;;;;;



;;;season 
   vint_beta_fi_jja_clm = get_season(vint_beta_fi,"JJA")
   vint_beta_fi_mam_clm = get_season(vint_beta_fi,"MAM")
   vint_beta_fi_son_clm = get_season(vint_beta_fi,"SON")
   vint_beta_fi_djf_clm = get_season(vint_beta_fi,"DJF")





;;;;;;
    res = True
    res@gsnDraw=False
    res@gsnFrame=False
    res@cnFillPalette = "BlRe"

    res@cnLinesOn=True
 
    res@cnFillOn =True
   
    res@cnLinesOn=True
    res@cnLevelSelectionMode ="ManualLevels"
    res@cnMinLevelValF = -12
    res@cnMaxLevelValF = 12
    res@cnLevelSpacingF = 2
    res@lbLabelBarOn =False
    res@cnLineLabelsOn = False
    res@cnInfoLabelOn = False
    res@lbLabelBarOn = False
    
    res@tiYAxisString=""
    res@tmXTOn=False
    res@tmYROn=False
    res@tmXBMode="Explicit"
  
    ; res@tmXBValues=(/0,90,180,270,357.5/)
    ; res@tmXBLabels=(/"0","90~S~o~N~E","180","90~S~o~N~W","0"/)
    
    res@tmXBMinorOn=True
    res@tmXBMinorValues=ispan(-90,90,10)

    ; res@tmXBValues=ispan(100,310,40)
    ; res@tmXBLabels=(/"100~S~o~N~E","140~S~o~N~E","180~S~o~N~E","140~S~o~N~W","100~S~o~N~W","60~S~o~N~W"/)
    ; res@tmXBMinorOn=True
    ; res@tmXBMinorValues=ispan(100,310,10)
    res@tmYRMode="Automatic"
     
    res@vpHeightF=0.3
    res@vpWidthF=0.7


    ; res@vcRefMagnitudeF = 0.2               ; define vector ref mag
    ; res@vcRefLengthF    = 0.04       ; define length of vec ref
    ; res@vcGlyphStyle    = "FillArrow"     ; turn on curly vectors
    ; res@vcMinDistanceF  = 0.03      ; thin out vectors
    ; res@vcMapDirection  = False
    ; res@vcLineArrowThicknessF=2.0
    ; ; res@vcFillArrowHeadXF=0.1
    ; res@vcFillArrowMinFracWidthF=1.0
    ; res@vcFillArrowHeadMinFracYF=1.0
    ; ; res@vcFillArrowHeadXF=1.0
    ; res@vcFillArrowWidthF=0.05
    ; res@vcFillArrowHeadYF=0.15
    
    ; res@vcLineArrowHeadMaxSizeF=0.005
    ; res@vcLineArrowHeadMinSizeF=0.005
   

    ;;;;

    wks2 = gsn_open_wks("pdf", "哈德莱环流气候态")
    
    plot_diff = new(4,graphic)
    res@gsnLeftString = "Spring"
    plot_diff(0) = gsn_csm_pres_hgt(wks2,vint_beta_fi_mam_clm,res)
    res@gsnLeftString = "Summer"
    plot_diff(1) = gsn_csm_pres_hgt(wks2,vint_beta_fi_jja_clm,res)
   res@gsnLeftString = "Autumn"
    plot_diff(2) = gsn_csm_pres_hgt(wks2,vint_beta_fi_son_clm ,res)
    res@gsnLeftString = "Winter"
    plot_diff(3) = gsn_csm_pres_hgt(wks2,vint_beta_fi_djf_clm,res)
 


 

   pres = True
   pres@gsnPanelLabelBar = True
   gsn_panel(wks2, plot_diff, (/2,2/), pres)


    end 