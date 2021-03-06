;;********************************************************
;;计算SST倾向以及SST值与GPCP降水的趋势
;;其中热通量的方向都是向上为正，向下为负
;;的相关系数场，
;;NCEP-NCAR的精度为1.87×1.9
;;
;;                                         lnshuheng 2020.02.18
;**********************************************************
function chazhi(data)
 begin
   xi = data&lon
   yi = data&lat
   xo = fspan(0.5,359.5,360)
   yo = fspan(-89.5,89.5,180)
 
   data_chazhi = linint2_Wrap(xi, yi, data, True, xo, yo, 0)
  
   data_chazhi!1 = "lat"
   data_chazhi!2= "lon"
   
   data_chazhi&lat = yo
   data_chazhi&lon = xo
   copy_VarAtts(data, data_chazhi)
 
   return data_chazhi
end 
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
;;**************************************************************
;;;main program
;;***************************************************************
begin
 ;;;time span
    startmon =197901
    endmon = 201612

    startyear_r = str_split_by_length(startmon, 4)  ;; 将时间string分解成年和月
    endyear_r = str_split_by_length(endmon, 4 )

    startyear = stringtoint(startyear_r(0))
    endyear = stringtoint(endyear_r(0))

    yearnum = endyear - startyear +1
  ;;

 

;;;读入HadiSST海温数据
    diri="/home/ys17-19/lsh/data/sst/"
    fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
    f1=addfile(fils1, "r")
    date:=cd_calendar(f1->time, 1)

    timeind:=ind(date.le.endmon.and.date.ge.startmon)

    sst=lonFlip(f1->sst(timeind,:,:))
    printVarSummary(sst)

    ssta=(/rmMonAnnCycTLL(sst)/)
    copy_VarCoords(sst, ssta)
    ;;;
    delete(date)
    delete(timeind)
;;;


;;;read GPCP precipitation data
    
    f2=addfile("/home/yangsong3/data-observation/GPCP/precip.mon.mean.nc", "r")   
    date:=cd_calendar(f2->time, 1)
    timeind:=ind(date.ge.startmon.and.date.le.endmon)
    p=f2->precip(timeind,:,:)
    printVarSummary(p)
    

    p_chazhi = chazhi(p)
    printVarSummary(p_chazhi)
 
    p_chazhi=(/rmMonAnnCycTLL(p_chazhi)/)
;;;; 

;;;;
    wks   = gsn_open_wks("pdf", "GPCP与SST的相关系数-season")
    wks1   = gsn_open_wks("pdf", "GPCP与dSST的相关系数-season")
    plot=new(4,graphic)
    plot1 = plot  
    str = (/"1","2","3","4"/)
    str1 = ispan(5,8,1) + ""
    iplot = new(4,graphic)
    iplot1 = iplot
    season =  (/"MAM","JJA","SON","DJF"/)

do i =0,3
  ;;;region
   lat1 = -5
   lat2 = 30
   lon1 = 100
   lon2 = 170
  ;;;

 
    ssta_annual = month_to_season(ssta(:,{lat1:lat2},{lon1:lon2}), season(i))
    printVarSummary(ssta_annual)

    ssta_annual =  (/dtrend_msg_n(ispan(1,yearnum,1),ssta_annual,False,True,0)/)

    ;;;sst 倾向值

    dsst = center_finite_diff_n(ssta, 1, False, 0, 0) 
    copy_VarCoords(ssta, dsst)
    dsst_annual =  month_to_season(dsst(:,{lat1:lat2},{lon1:lon2}), season(i))
    dsst_annual =  (/dtrend_msg_n(ispan(1,yearnum,1),dsst_annual,False,True,0)/)


    ; dsst_annual = center_finite_diff_n(ssta_annual, 1, False, 0, 0) 
    copy_VarCoords(ssta_annual, dsst_annual)
    
    p_annual = month_to_season(p_chazhi(:,{lat1:lat2},{lon1:lon2}), season(i))

    p_annual =  (/dtrend_msg_n(ispan(1,yearnum,1),p_annual,False,True,0)/)

   
 
  print("*******开始计算相关系数*****************")
  ;;;calculate correlation coef

    ;;;correlation with sst
    r_sst_p =  escorc_n(ssta_annual, p_annual, 0, 0)
    ;;;;

    r_dsst_p =  escorc_n(dsst_annual, p_annual, 0, 0)
      
    copy_VarCoords(ssta_annual(0,:,:), r_sst_p)
    copy_VarCoords(dsst_annual(0,:,:), r_dsst_p)
 


    ;;;;;
;;;;

    print("*******显著性检验*****************")

    ;;;t test 
    prob_p1= rtest(r_sst_p,yearnum,0)
    prob_p2= rtest(r_dsst_p,yearnum,0)

    copy_VarCoords(r_sst_p, prob_p1)
    copy_VarCoords(r_dsst_p, prob_p2)

    printVarSummary(prob_p1)
    prob_p1 = where(prob_p1.eq.0, 2, prob_p1)
    prob_p2 = where(prob_p2.eq.0, 2, prob_p2)

  ;;;;


  print("*********开始画图********")

;;**************************************************************
;画图
;;***************************************************************


  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  ; res@cnFillPalette="BlueDarkRed18"
  res@cnFillPalette = "BlueWhiteOrangeRed"
  res@cnFillOn=True
  res@cnLinesOn=False
  res@gsnAddCyclic = False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=False
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  res@mpMinLatF             = lat1
  res@mpMaxLatF             = lat2
  res@mpMinLonF             = lon1
  res@mpMaxLonF             = lon2
  


  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False
  res@tmXBMode="Explicit"
  res@tmYLMode="Explicit"

  res@tmXBLabelFontHeightF=0.015
  res@tmYLLabelFontHeightF=0.015
  res@tmXBMajorThicknessF=1.0
  res@tmYLMajorThicknessF=1.0
  res@tmBorderThicknessF=1.0

  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   -0.8
  res@cnMaxLevelValF       =   0.8
  res@cnLevelSpacingF      =  0.2

 
  res@gsnLeftString = season(i)+" Corr.SST&Pre"
  plot(i) = gsn_csm_contour_map(wks, r_sst_p, res)
  res@gsnLeftString = season(i)+"_DSST&Pre"
  plot1(i) = gsn_csm_contour_map(wks1, r_dsst_p, res)
 
  ;;;添加赤道直线
    pgx=ispan(30,390,10)
    pgy=new(dimsizes(pgx),typeof(pgx))
    pgy=0

    pgres=True
    pgres@gsLineColor="black"
    pgres@gsLineThicknessF=1.0
    pgres@gsLineDashPattern=1
  

   plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
   plot1@$str(i)$ = gsn_add_polyline(wks1, plot1(i), pgx, pgy, pgres)



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

   
   plot@$str1(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
   plot1@$str1(i)$ = gsn_add_polyline(wks1, plot1(i), pgx_pool, pgy_pool, pgres)


    ;;;打点
    res_pro=True
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLinesOn=False
    res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
    res_pro@cnMinLevelValF      = 0.00        ; set min contour level
    res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
    res_pro@cnLevelSpacingF     = 0.1       ; set contour spacing

    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False



    iplot(i) = gsn_csm_contour(wks,prob_p1,res_pro)
    iplot1(i) = gsn_csm_contour(wks1,prob_p2,res_pro)
     
    

    opt                      = True
    opt@gsnShadeFillType     = "pattern"
    opt@gsnShadeMid     = 17         ; stipple
    ; opt@gsnShadeFillDotSizeF =  0.0025
    ; opt@gsnShadeHigh   = "green"
    opt@gsnShadeFillScaleF   = 0.5         ; add extra density ,越大越係數

     iplot(i) = gsn_contour_shade(iplot(i) , 0,0.1,opt)
     iplot1(i) = gsn_contour_shade(iplot1(i) , 0,0.1,opt)


    ;;;  
    
      overlay(plot(i), iplot(i))
      overlay(plot1(i), iplot1(i))
      delete(lat1)
      delete(lat2)
      delete(lon1)
      delete(lon2)
end do

  pres = True
  pres@gsnPanelLabelBar  = True

  gsn_panel(wks, plot, (/2,2/), pres)
  gsn_panel(wks1, plot1, (/2,2/), pres)
 

end