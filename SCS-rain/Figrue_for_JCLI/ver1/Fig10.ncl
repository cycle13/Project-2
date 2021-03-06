;;;************************************************************
;;
;; linshuheng 2019.10.22
;;;*********************************************************
function t_test(series1,series2)
begin
  ;;;ttest 
      avg1 = dim_avg_n_Wrap(series1, 0)
      avg2 = dim_avg_n_Wrap(series2, 0)
      
      dim = dimsizes(avg1)
      simple_size =  avg1
      simple_size = dim(0)
    
      simple_variance1  = dim_variance_n_Wrap(series1, 0)
      simple_variance2  = dim_variance_n_Wrap(series2, 0)

      prob_p = ttest(avg1 ,simple_variance1, simple_size, avg2 ,simple_variance2 ,simple_size,False,False)
     copy_VarCoords(avg1, prob_p)
return prob_p
end 
begin


  fils1 = "/home/yangsong3/data-observation/linshh/CESM-data/B/B2000_alt_north_year_CTRL/B2000_alt_north_year_CTRL.cam.h1.0251-0280_OLR_heatflux.nc"
  fils2 = "/home/yangsong3/data-observation/linshh/CESM-data/B/B2000_alt_north_year/B2000_alt_north_year.cam.h1.0251-0280_OLR_heatflux.nc"
 
  
    f1=addfile(fils1, "r")
    f2=addfile(fils2, "r")
    
    time1 = f1->time
    time2 = f2->time
    time1 = (/time1 -1/)
    time2 = (/time2 -1/)
    date1=cd_calendar(time1, 1)
    date2=cd_calendar(time2, 1)


    timeind1=ind(date1.ge.25601.and.date1.le.28012)
    timeind2=ind(date2.ge.25601.and.date2.le.28012)

  
    PRECC_CT  =  f1->FLUT(timeind1,:,:)

    PRE_CT = PRECC_CT

  
   
    PRECC_id  =  f2->FLUT(timeind2,:,:)

    PRE_id = PRECC_id

   
    
    season = (/"MAM","JJA","SON","DJF"/)
    order  = (/"(a)","(b)","(c)","(d)"/)

    wks=gsn_open_wks("pdf", "diff-olr-altantic-year-fourseason-0280.pdf")

    plot = new(4,graphic)
    str3 = ispan(1, 4, 1) +""
    plot1 =new(4,graphic)
    iplot = new(4,graphic)


  do i=0,3


    PRE_CT_clm = dim_avg_n_Wrap(month_to_season(PRE_CT, season(i)), 0)
    PRE_indian_clm =dim_avg_n_Wrap(month_to_season(PRE_id, season(i)), 0)

    PRE_diff = PRE_CT_clm
    PRE_diff = (/PRE_indian_clm - PRE_CT_clm/)

    

    ;;;t_test 
     prob_pre_indian = t_test(month_to_season(PRE_CT, season(i)),month_to_season(PRE_id, season(i)))
     copy_VarCoords(PRE_indian_clm, prob_pre_indian)
    
    
         
    res=True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnAddCyclic=True

    res@lbLabelBarOn=False
    res@cnFillOn = True 
    res@cnLinesOn =False
    res@trGridType = "TriangularMesh"
    res@cnLineLabelsOn = False

    ; res@cnFillPalette = "BlueDarkRed18"
     res@cnFillPalette ="CBR_coldhot"

    res@tmXBLabelFontHeightF=0.025
    res@tmYLLabelFontHeightF=0.025
    res@tmXBMajorThicknessF=1.0
    res@tmYLMajorThicknessF=1.0
    res@tmBorderThicknessF=1.0
    res@gsnLeftStringFontHeightF = 0.025


    res@gsnRightString = ""
    res@gsnLeftString = order(i)+" "+ season(i)+ " OLR diff(AT - CPL_CTRL)"


    
    ; res@cnFillPalette = "MPL_bwr"
    res@cnFillPalette = "BlueWhiteOrangeRed"
    ; res@cnFillPalette= "BlRe"

    res@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
    res@cnLevels := (/-1.0,-0.8,-0.6,-0.4,-0.2,0.2,0.4,0.6,0.8,1.0/)*10.0
    ; res@cnLevels := (/-20.,-15.,-10.,-5.,5.,10.,15.,20./)




    res@tmXTOn=False
    res@tmYROn=False

    res@mpLimitMode           = "LatLon"

    res@mpMinLatF             = -5.0
    res@mpMaxLatF             = 30.0
    ; res@mpMaxLatF             = 50.0
    res@mpMinLonF             = 100.0
    res@mpMaxLonF             = 170.0


    res@tmXBValues = (/100,120,140,160/) 
    res@tmXBLabels = (/100,120,140,160/) +""+"E" 

    res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0


    res@mpFillOn = False
    res@mpGeophysicalLineColor      = "Grey18"
    res@mpGeophysicalLineThicknessF = 1.5

    res@gsnRightString = ""


    plot(i) = gsn_csm_contour_map(wks, PRE_diff, res)


    ;;;画box
    pgres=True
    pgres@gsLineColor="black"
    pgres@gsLineThicknessF=2.0
    pgres@gsLineDashPattern=0

    lat1 = 0
    lat2 = 15
    lon1 = 125
    lon2 = 160

    pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
    pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)

    ;;;

    plot1@$str3(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres) 


    ;;;打点
    res_pro=True
    res_pro@gsnAddCyclic = False
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnFillOn = True

    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLevels = (/0,0.05/)
    res_pro@lbLabelBarOn = False
    res_pro@cnLinesOn=False
    ; res_pro@cnMonoLineColor =False
    ; res_pro@cnLineColors = ((/"Transparent","White","Transparent"/))

    res_pro@cnMonoFillPattern = True
    res_pro@cnFillPattern = 17
    res_pro@cnFillDotSizeF = 0.002

    res_pro@cnMonoFillColor = False
    res_pro@cnFillColors = (/"Transparent","black","Transparent"/)
    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False

    res_pro@gsnCenterString = ""
    iplot(i)=gsn_csm_contour(wks,prob_pre_indian,res_pro)
    overlay(plot(i), iplot(i))







end do 
    pres = True
    pres@gsnPanelLabelBar = True
     pres@lbLabelStride=1
    pres@lbLabelFontHeightF = 0.015
    
    gsn_panel(wks, plot, (/2,2/), pres)
    print("done script")
  end
  