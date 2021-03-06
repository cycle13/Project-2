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

function cal_season_trend(data,season)
  begin
    p_djf_r=month_to_season(data, season)
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

    sst=f1->sst(timeind,:,:)
    ssta= sst
    ; copy_VarCoords(sst, ssta)
   

   ;;;;cal season trend 
  
    ssta_mam = dim_avg_n_Wrap(month_to_season(ssta, "MAM"), 0)
    ssta_jja = dim_avg_n_Wrap(month_to_season(ssta, "JJA"), 0)
    ssta_son = dim_avg_n_Wrap(month_to_season(ssta, "SON"), 0)
    ssta_djf = dim_avg_n_Wrap(month_to_season(ssta, "DJF"), 0)



    ssta_jja = (/ssta_jja - ssta_mam/)
    ssta_son = (/ssta_son - ssta_mam/)
    ssta_djf = (/ssta_djf - ssta_mam/)
    ssta_mam = 0.0


    
    
    wks   = gsn_open_wks("pdf", "季节平均SST的气候态-SCS-79-15-global-minus-spring")
;;**************************************************************
;画图
;;***************************************************************

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  
  ; res@cnFillPalette = "matlab_jet"
   ; res@cnFillPalette = "BlueWhiteOrangeRed"
   res@cnFillPalette = "BlueRed"
  ; res@gsnSpreadColorStart = 130
  ; res@gsnSpreadColorEnd = 253
  res@cnFillOn=True
  res@cnLinesOn=True

  res@cnLineLabelsOn=False
  res@lbLabelBarOn=False
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  ; res@mpLimitMode           = "LatLon"
  ; res@mpMinLatF             = -60
  ; res@mpMaxLatF             = 60
  ; res@mpMinLonF             =0
  ; res@mpMaxLonF             = 360

  res@mpMinLatF             = -5
  res@mpMaxLatF             = 30
  res@mpMinLonF             = 70
  res@mpMaxLonF             = 170



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

  ; res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  ; res@cnMinLevelValF       =   23
  ; res@cnMaxLevelValF       =   30
  ; res@cnLevelSpacingF      =  0.5



  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   -2
  res@cnMaxLevelValF       =   2
  res@cnLevelSpacingF      =  0.4
  res@cnInfoLabelOn = False
  

  res@gsnLeftString="Spring"

  plot=new(4,graphic)

  plot(0) = gsn_csm_contour_map(wks, ssta_mam, res)
    res@gsnLeftString="Summer"
  plot(1) = gsn_csm_contour_map(wks, ssta_jja, res)
    res@gsnLeftString="Autumn"
  plot(2) = gsn_csm_contour_map(wks, ssta_son, res)
    res@gsnLeftString="Winter"
  plot(3) = gsn_csm_contour_map(wks, ssta_djf, res)

  res2 = res
  res2@cnLevelSelectionMode = "ExplicitLevels"
  res2@cnFillOn = False
  res2@cnLinesOn = True
  res2@cnLevels = (/0.55/)
  res2@cnLineColors = "black"
  res2@cnMonoLineColor  = True
  res2@cnLineThicknessF = 5
  res2@cnMonoLineThickness  = True
  res2@gsnLeftString = ""
  res2@cnInfoLabelOn = False
  
  plot1=new(4,graphic)

  plot1(0) = gsn_csm_contour(wks, ssta_mam, res2)
  plot1(1) = gsn_csm_contour(wks, ssta_jja, res2)
  plot1(2) = gsn_csm_contour(wks, ssta_son, res2)
  plot1(3) = gsn_csm_contour(wks, ssta_djf, res2)

  ; do i=0,3
  ; overlay(plot(i), plot1(i))
  ; end do   

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
  do i = 0,3
  plot_add(i) = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
   end do 
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
   lon1 = 110
   lon2 = 155

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;

    str2 = ispan(1, 4, 1) + ""
     plot_add2 = new(4,graphic)
    do i = 0,3
      plot_add2(i) = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
    end do 

  
pres = True
pres@gsnPanelLabelBar  = True
gsn_panel(wks, plot, (/2,2/), pres)

end