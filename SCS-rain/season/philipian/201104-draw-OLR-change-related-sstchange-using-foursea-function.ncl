;;********************************************************
;;画HadIsst的sst趋势
;;
;;lnshuheng 2020.02.17
;**********************************************************
function  rc_test(ssta_rc)
begin
  tval = onedtond(ssta_rc@tval , dimsizes(ssta_rc))
   df   = onedtond(ssta_rc@nptxy, dimsizes(ssta_rc)) - 2
   b = tval    ; b must be same size as tval (and df)
   b = 0.5
   prob = betainc(df/(df+tval^2),df/2.0,b)    ; prob(nlat,nlon)
   copy_VarCoords(ssta_rc, prob)
return prob
end

undef("remove_enso_signal")
function remove_enso_signal(data)
  begin  
  ; ;;;读入HadiSST海温数据
      diri="/home/yangsong3/data-observation/linshh/data/sst/"
      fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
      f1=addfile(fils1, "r")
      date:=cd_calendar(f1->time, 1)

      timeind:=ind(date.le.201512.and.date.ge.197901)

      sst =  lonFlip(f1->sst(timeind,:,:))
   
      ssta=(/rmMonAnnCycTLL(sst)/)
      copy_VarCoords(sst, ssta)

      ssta_de = ssta
      ; ssta_de=(/dtrend_msg_n(ispan(1,dimsizes(ssta&time),1),ssta,False,True,0)/)
      ssta_index = dim_avg_n_Wrap(ssta_de(:,{5:-5},{190:240}), (/1,2/))
      printVarSummary(ssta_index)

      nino3_4 = month_to_season(ssta_index, "DJF")   ;;;第一年是JF平均，第二年是DJF平均
      printVarSummary(nino3_4)

      
      ; nino3_4_new = nino3_4                ;;;;前期ENSO
      ; nino3_4_new(0:33) = (/nino3_4(1:)/)
      ; nino3_4_new(34) =ssta_index(35*12-1) 
   
      nino3_4 = (/dim_standardize_n(nino3_4, 1, 0)/)
  ;;;;;
      data_de = data
      ; data_de=(/dtrend_msg_n(ispan(1,dimsizes(data&time),1),data,False,True,0)/) 
      data_rc = regCoef_n(nino3_4,data_de, 0, 0)
      copy_VarCoords(data(1,:,:), data_rc)
      data_rc_3d  = conform_dims(dimsizes(data), data_rc, (/1,2/))
      m = reshape(data_rc@yintercept,dimsizes(data_rc_3d)) 
      nino3_4_3d = conform(data_rc_3d,nino3_4,(/0/))
  
      data_relate_enso  = nino3_4_3d*data_rc_3d + m 
      data_new = data 
      data_new = (/data - data_relate_enso/)
  return data_new
end 

function cal_season_trend(data,season)
  begin
   
    p_djf_r=month_to_season(data, season)
     ; ;;;;remove_enso_signal
     ;     p_djf_r = (/remove_enso_signal(p_djf_r)/)
     ; ;;;;

      if season.eq."DJF"
      p_djf_r(0:dimsizes(p_djf_r&time)-2,:,:) = p_djf_r(1:,:,:)
      p_djf_r(dimsizes(p_djf_r&time)-1,:,:) = data(dimsizes(data&time)-1,:,:)
    end if
    dim = dimsizes(p_djf_r)
    p_rc=regCoef_n(ispan(1, dim(0), 1), p_djf_r, 0, 0)
    copy_VarCoords(p_djf_r(1,:,:), p_rc)
    p_rc=(/p_rc*dim(0)/)
  return p_rc
end 



function eot_mam(sst_mam_clm)          ;;;; -15.2953*x+413.097(27.5~28.75) 26.2733*x+-787.921 (28.75~30.25)                                     
 begin 
  eot = sst_mam_clm
  eot = 0.0
  eot =  where(sst_mam_clm.lt.27.5, 0.0, eot)
  eot =  where(sst_mam_clm.ge.27.5.and.sst_mam_clm.le.28.75,  -15.2953*sst_mam_clm + 413.097 , eot)
  eot =  where(sst_mam_clm.gt.28.75.and.sst_mam_clm.le.30.25,  26.2733*sst_mam_clm -787.921, eot)
  return eot
 end 

function eot_jja(sst_mam_clm)          ;;;; -12.3128*x+325.417(28.0,28.75,4) 27.3584*x+-810.735 (28.75,30.25 ）                                   
 begin 
  eot = sst_mam_clm
  eot = 0.0
  eot =  where(sst_mam_clm.lt.28.0, 0.0, eot)
  eot =  where(sst_mam_clm.ge.28.0.and.sst_mam_clm.le.28.75,  -12.3128*sst_mam_clm +325.417 , eot)
  eot =  where(sst_mam_clm.gt.28.75.and.sst_mam_clm.le.30.25, 27.3584*sst_mam_clm -810.735, eot)
  return eot
 end 
 

 function eot_son(sst_mam_clm)          ;;;; 8.19301*x+-251.244  （28.0,30.25,）                                   
 begin 
  eot = sst_mam_clm
  eot = 0.0
  eot =  where(sst_mam_clm.lt.28.0, 0.0, eot)
  eot =  where(sst_mam_clm.ge.28.0.and.sst_mam_clm.le.30.25, 8.19301*sst_mam_clm -251.244 , eot)
  return eot
 end 


function eot_djf(sst_mam_clm)       ;;-13.6601*x+365.899 (27.5~28.75)   20.2962*x+-612.16       (28.75~30.25)                                    
 begin 
  eot = sst_mam_clm
  eot = 0.0
  eot =  where(sst_mam_clm.lt.27.5, 0.0, eot)
  eot =  where(sst_mam_clm.ge.27.5.and.sst_mam_clm.le.28.75,  -13.6601*sst_mam_clm +365.899, eot)
  eot =  where(sst_mam_clm.gt.28.75.and.sst_mam_clm.le.30.25,  20.2962*sst_mam_clm -612.16  , eot)
  return eot
 end 

;;**************************************************************
;;;main program
;;***************************************************************
begin
  
   ;;;读入HadiSST海温数据
    diri="/home/yangsong3/data-observation/linshh/data/sst/"
    fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
    f1=addfile(fils1, "r")
    date:=cd_calendar(f1->time, 1)

    timeind:=ind(date.le.201512.and.date.ge.197901)

    sst  = f1->sst(timeind,{-5:30},{100:170})

    sst_mam_clm = dim_avg_n_Wrap(month_to_season(sst, "MAM"), 0)


    sst_jja_clm = dim_avg_n_Wrap(month_to_season(sst, "JJA"), 0)
    sst_son_clm = dim_avg_n_Wrap(month_to_season(sst, "SON"), 0)
    sst_djf_clm = dim_avg_n_Wrap(month_to_season(sst, "DJF"), 0)

    ssta=(/rmMonAnnCycTLL(sst)/)
    copy_VarCoords(sst, ssta)
    

   ;;;;cal season trend 
    ssta_mam = cal_season_trend(ssta,"MAM")
    ssta_jja = cal_season_trend(ssta,"JJA")
    ssta_son  = cal_season_trend(ssta,"SON")
    ssta_djf = cal_season_trend(ssta,"DJF")
    
    ; ssta_jja = (/ssta_jja - ssta_mam/)
    ; ssta_son = (/ssta_son- ssta_mam/)
    ; ssta_djf = (/ssta_djf -ssta_mam/)
    ; ssta_mam = 0.0

    prob_mam = rc_test(ssta_mam)
    prob_jja = rc_test(ssta_jja)

    prob_son = rc_test(ssta_son)
    prob_djf = rc_test(ssta_djf)

    eot_mam_r = eot_mam(sst_mam_clm)
    eot_jja_r = eot_jja(sst_jja_clm)   
    eot_son_r = eot_son(sst_son_clm)
    eot_djf_r = eot_djf(sst_djf_clm)

    
    olr_rela_mam  = ssta_mam
    olr_rela_jja  = ssta_mam
    olr_rela_son  = ssta_mam
    olr_rela_djf  = ssta_mam


  
    olr_rela_mam = (/eot_mam_r*ssta_mam/)
    olr_rela_jja = (/eot_jja_r*ssta_jja/)
    olr_rela_son = (/eot_son_r*ssta_son/)
    olr_rela_djf = (/eot_djf_r*ssta_djf/)
   

    ; ssta_mam = where(prob_mam.le.0.1, ssta_mam, ssta_mam@_FillValue)
    ; ssta_jja = where(prob_jja.le.0.1, ssta_jja, ssta_jja@_FillValue)
    ; ssta_son = where(prob_son.le.0.1, ssta_son, ssta_son@_FillValue)
    ; ssta_djf = where(prob_djf.le.0.1, ssta_djf, ssta_djf@_FillValue)

    ; ssta_mam = where(prob_mam.le.0.1, ssta_mam, ssta_mam@_FillValue)
    ; ssta_jja = where(prob_jja.le.0.1, ssta_jja, ssta_jja@_FillValue)
    ; ssta_son = where(prob_son.le.0.1, ssta_son, ssta_son@_FillValue)
    ; ssta_djf = where(prob_djf.le.0.1, ssta_djf, ssta_djf@_FillValue)
    
    
    
    ; wks   = gsn_open_wks("pdf", "global季节平均SST的趋势-philipian-79-16")
    wks   = gsn_open_wks("pdf", "OLR-change-related-to-SSTchange-79-15-fourseasonfuction-wep")
;;**************************************************************
;画图
;;***************************************************************

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnAddCyclic = False
  
 
   ; res@cnFillPalette = "BlueWhiteOrangeRed"
   res@cnFillPalette = "BlueDarkRed18"
   ; res@cnFillPalette = "BlRe"

  ; res@gsnSpreadColorStart = 130
  ; res@gsnSpreadColorEnd = 253
  res@cnFillOn=True
  res@cnLinesOn=False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=False
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  ; res@mpMinLatF             = -30
  ; res@mpMaxLatF             = 30
  ; res@mpMinLonF             =0
  ; res@mpMaxLonF             = 360

  res@mpMinLatF             = -5
  res@mpMaxLatF             = 30
  res@mpMinLonF             = 100
  res@mpMaxLonF             = 170

  ; res@mpMinLatF             = 0
  ; res@mpMaxLatF             = 15
  ; res@mpMinLonF             = 125
  ; res@mpMaxLonF             = 160

  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False
  res@tmXBMode="Explicit"
  res@tmYLMode="Explicit"



  res@tmXBLabelFontHeightF=0.025
  res@tmYLLabelFontHeightF=0.025
  res@tmXBMajorThicknessF=1.0
  res@tmYLMajorThicknessF=1.0

  res@tmXBValues = (/100,120,140,160/) 
  res@tmXBLabels = (/100,120,140,160/) +""+"E" 

  res@gsnLeftStringFontHeightF = 0.03


  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   -12.0
  res@cnMaxLevelValF       =   12.0
  res@cnLevelSpacingF      =  2.0
  ; res@cnFillPalette = "NCV_jaisnd"
  res@cnFillPalette= "BlueWhiteOrangeRed"
  ; res@cnFillPalette = "sunshine_9lev"
  ; res@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
  ; res@cnLevels = (/-1.5,-1.0,-0.5,-0.25,0.25,0.5,1.0,1.5,2.0,2.5/)
  ; res@cnFillColors= (/4,5,6,7,8,9,10,11,12,13,14/) - 2

  res@cnInfoLabelOn = False
  

  res@gsnLeftString="(a) MAM OLR change related to SST change"


  ; res@mpShapeMode = "FreeAspect"
  ; res@vpHeightF = 0.2
  ; res@vpWidthF = 0.7

  plot=new(4,graphic)

  ; plot(0) = gsn_csm_contour_map(wks, olr_rela_mam({0:15},{125:160}), res)
  ; res@gsnLeftString="(b) JJA OLR change related to SST change"
  ; plot(1) = gsn_csm_contour_map(wks, olr_rela_jja({0:15},{125:160}), res)
  ; res@gsnLeftString="(c) SON OLR change related to SST change"
  ; plot(2) = gsn_csm_contour_map(wks, olr_rela_son({0:15},{125:160}), res)
  ; res@gsnLeftString="(d) DJF OLR change related to SST change"
  ; plot(3) = gsn_csm_contour_map(wks, olr_rela_djf({0:15},{125:160}), res)

    plot(0) = gsn_csm_contour_map(wks, olr_rela_mam, res)
  res@gsnLeftString="(b) JJA OLR change related to SST change"
  plot(1) = gsn_csm_contour_map(wks, olr_rela_jja, res)
  res@gsnLeftString="(c) SON OLR change related to SST change"
  plot(2) = gsn_csm_contour_map(wks, olr_rela_son, res)
  res@gsnLeftString="(d) DJF OLR change related to SST change"
  plot(3) = gsn_csm_contour_map(wks, olr_rela_djf, res)


  res2 = res
  res2@cnLevelSelectionMode = "ExplicitLevels"
  res2@cnFillOn = False
  res2@cnLinesOn = True
  res2@cnLevels = fspan(26.0, 30.0, 9)
  res2@cnLineLabelStrings =   res2@cnLevels  + ""
  res2@cnLineLabelDensityF = 1.3


  res2@cnLineColors = "black"
  res2@cnMonoLineColor  = True
  res2@cnLineThicknessF = 2
  res2@cnMonoLineThickness  = True
  res2@gsnLeftString = ""
  res2@cnInfoLabelOn = False
  res2@cnLineLabelsOn = True
  res2@cnLineLabelInterval = 1
  res2@cnLineLabelBackgroundColor = "White"
  
  plot1=new(4,graphic)

  plot1(0) = gsn_csm_contour(wks, sst_mam_clm, res2)
  plot1(1) = gsn_csm_contour(wks, sst_jja_clm, res2)
  plot1(2) = gsn_csm_contour(wks, sst_son_clm, res2)
  plot1(3) = gsn_csm_contour(wks, sst_djf_clm, res2)

  do i=0,3
  overlay(plot(i), plot1(i))
  end do   

   str1 = unique_string("dum1")  ; "unique_string" will return a unique    


  ;;;添加赤道直线
   pgx=ispan(30,390,10)
   pgy=new(dimsizes(pgx),typeof(pgx))
   pgy=0
   
   pgres=True
   pgres@gsLineColor="black"
   pgres@gsLineThicknessF=1.0
   pgres@gsLineDashPattern=1

  str = ispan(1, 4, 1) + ""
    plot_add = new(4,graphic)
  ; do i = 0,3
  ; plot_add(i) = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
  ;  end do 
  ;;;添加indo-pacific warm pool
    ; ;;添加区域
   ;;warm pool
   pgres@gsLineThicknessF=2.0
   pgres@gsLineDashPattern=0
   str3=unique_string("dum3")
   str4=unique_string("dum4")
   
   ;;;画box
   lat1 = 0
   lat2 = 15
   lon1 = 125
   lon2 = 160

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;

    str2 = ispan(1, 4, 1) + ""
     plot_add2 = new(4,graphic)
    do i = 0,3
      plot_add2(i) = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
    end do 

   ;;;打点
    res_pro=True
    res_pro@gsnAddCyclic = False
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnFillOn = True

    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLevels = (/0,0.1/)
    res_pro@lbLabelBarOn = False
    res_pro@cnLinesOn=False
    ; res_pro@cnMonoLineColor =False
    ; res_pro@cnLineColors = ((/"Transparent","White","Transparent"/))

    res_pro@cnMonoFillPattern = True
    res_pro@cnFillPattern = 17
    res_pro@cnFillDotSizeF = 0.001
    res_pro@cnMonoFillColor = False
    res_pro@cnFillColors = (/"Transparent","White","Transparent"/)
    ; res_pro@cnLevels = ispan(-6,6,1)
    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False
    ; res_pro@cnLineLabelBackgroundColor="Transparent"
    ; res_pro@cnLineThicknessF = 3.
    ; res_pro@cnFillOn        = True
  
     iplot = new(4,graphic)
     iplot(0) = gsn_csm_contour(wks,prob_mam  ,res_pro)
     iplot(1) = gsn_csm_contour(wks,prob_jja  ,res_pro)
     iplot(2) = gsn_csm_contour(wks,prob_son  ,res_pro)
     iplot(3) = gsn_csm_contour(wks,prob_djf  ,res_pro)
    ;  
    do i=0,3
     overlay(plot(i), iplot(i))
    end do

pres = True
pres@gsnPanelLabelBar  = True
pres@gsnMaximize = True
; pres@lbOrientation = "Vertical"
pres@lbOrientation = "Horizontal"
; pres@pmLabelBarHeightF = 0.3
pres@lbLabelFontHeightF = 0.02
; pres@lbLabelStride = 2
gsn_panel(wks, plot, (/2,2/), pres)

end