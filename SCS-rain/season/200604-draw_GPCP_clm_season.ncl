;;********************************************************
;;画GPCP的季节气候态
;;
;;lnshuheng 2019.12.24
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



begin
    f2=addfile("/home/yangsong3/data-observation/GPCP/precip.mon.mean.nc", "r")
    date=cd_calendar(f2->time, 1)
    timeind=ind(date.ge.197901.and.date.le.201512)
    p=f2->precip(timeind,:,:)
   
    delete(p&time)
    p&time=date(timeind)
    printVarSummary(p)
    p_pi = p
    


    rc_mam = dim_avg_n_Wrap(month_to_season(p_pi, "MAM"), 0)
    rc_jja = dim_avg_n_Wrap(month_to_season(p_pi, "JJA"), 0)
    rc_son = dim_avg_n_Wrap(month_to_season(p_pi, "SON"), 0)
    rc_djf = dim_avg_n_Wrap(month_to_season(p_pi, "DJF"), 0)


    ; prob_mam=rc_test(rc_mam)
    ; prob_jja=rc_test(rc_jja)
    ; prob_son=rc_test(rc_son)
    ; prob_djf=rc_test(rc_djf)
    
    ; prob_mam = 1- rc_mam@prob
    ; prob_jja = 1- rc_jja@prob
    ; prob_son = 1- rc_son@prob
    ; prob_djf = 1- rc_djf@prob


    ; copy_VarCoords(p_pi(1,:,:), prob_mam)
    ; copy_VarCoords(p_pi(1,:,:), prob_jja)
    ; copy_VarCoords(p_pi(1,:,:), prob_son)
    ; copy_VarCoords(p_pi(1,:,:), prob_djf)

    
wks   = gsn_open_wks("pdf", "不同季节GPCP降水的气候态-scs-1979-2015")
;;**************************************************************
;画图
;;***************************************************************
      
  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  res@cnFillPalette="NCV_blu_red"
  res@cnFillOn=True
  res@cnLinesOn=False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=False
  res@lbLabelStride=2

  res@mpLimitMode           = "LatLon"
  
  res@mpMinLatF             = -60
  res@mpMaxLatF             = 60
  res@mpMinLonF             =0
  res@mpMaxLonF             = 360



  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False
  res@tmXBMode="Explicit"
  res@tmYLMode="Explicit"


  res@tmXBLabelFontHeightF=0.015
  res@tmYLLabelFontHeightF=0.015
  res@tmXBMajorThicknessF=3.0
  res@tmYLMajorThicknessF=3.0
  res@tmBorderThicknessF=4.0

  ; res@mpShapeMode="FreeAspect"
  ; res@vpHeightF=0.3
  ; res@vpWidthF=0.7

  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   0
  res@cnMaxLevelValF       =   10
  res@cnLevelSpacingF      =  1

  res@cnFillPalette="CBR_wet"
  res@gsnLeftString="Spring"

  plot = new(4,graphic)
  plot(0) = gsn_csm_contour_map(wks, rc_mam, res)
  res@gsnLeftString="Summer"
  plot(1) = gsn_csm_contour_map(wks, rc_jja, res)
  res@gsnLeftString="Autumn"
  plot(2) = gsn_csm_contour_map(wks, rc_son, res)
  res@gsnLeftString="Winter"
  plot(3) = gsn_csm_contour_map(wks, rc_djf, res)


  

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
   do i =0,3 
   plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
   end do 



  ;;;添加indo-pacific warm pool
    ; ;;添加区域
   ;;warm pool
   pgres@gsLineThicknessF=2.0
   pgres@gsLineDashPattern=0

   
   ;;;画box
   lat1 = 0
   lat2 = 15
   lon1 = 110
   lon2 = 155

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;

     str2 = ispan(21, 24, 1) +""
   do i =0,3 
     plot@$str2(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
  end do 


    ;;;打点
    res_pro=True
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLinesOn=False
    res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
    res_pro@cnMinLevelValF      = 0.00        ; set min contour level
    res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
    res_pro@cnLevelSpacingF     = 0.05       ; set contour spacing

    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False

    iplot=new(4,graphic)

    
 
    ; iplot(0) = gsn_csm_contour(wks,prob_mam,res_pro)    
    ; iplot(1) = gsn_csm_contour(wks,prob_jja,res_pro)
    ; iplot(2) = gsn_csm_contour(wks,prob_son,res_pro)
    ; iplot(3) = gsn_csm_contour(wks,prob_djf,res_pro)

    

  ;   opt                      = True
  ;   opt@gsnShadeFillType     = "pattern"
  ;   opt@gsnShadeMid     = 6         ; stipple
  ;   ; opt@gsnShadeFillDotSizeF =  0.0025
  ;   ; opt@gsnShadeHigh   = "green"
  ;   opt@gsnShadeFillScaleF   = 0.5         ; add extra density ,越大越係數

   
  ;    do i=0,3
  ;   iplot(i) = gsn_contour_shade(iplot(i) , 0,0.05,opt)
  ;    overlay(plot(i), iplot(i))
  ; end do

    ;;;  
   
pres = True
pres@gsnPanelLabelBar  = True
gsn_panel(wks, plot, (/2,2/), pres)

end;