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
;;;
function clm_ano(x[*]:numeric)  ;去除一维时间序列的年循环
begin

   dimx  = dimsizes (x)
   ntim  = dimx(0)

   nmos  = 12
   modCheck ("clm", ntim, nmos)   ; error check; Compute all 12 monthly averages first. 
   aveMonth = new((/nmos/),typeof(x) \
                                    ,getFillValue(x))

   do nmo=0,nmos-1
      aveMonth(nmo) = dim_avg( x(nmo:ntim-1:nmos) )
   end do
   copy_VarAtts (x,aveMonth)
   aveMonth!0   = "month"           ; create a "month" named dim
   aveMonth&month = ispan(0,nmos-1,1) ; create a month coord var
   xAnom=x
   do yr=0,ntim-1,nmos
      xAnom(yr:yr+nmos-1) = (/ x(yr:yr+nmos-1)- aveMonth /)
   end do
   return (xAnom)
end
;;;


function  regress_msf(str,eofnum,wks,rightstr)
begin
  ipindex1=asciiread("/mnt/f/share/GISS/giss_gtemp_1979_2012.ascii", 34, "float")
  ipindex2=asciiread("/mnt/f/share/GISS/giss_ipo_1979_2012.ascii", 34, "float")

  diri="/mnt/f/share/"
  fils1=diri+str
  print(fils1)

  f1=addfile(fils1, "r")
  date=cd_calendar(f1->time, 1)
 
  timeind=ind(date.ge.197901.and.date.le.201212)

  msf_time=f1->msf_time(:,:,timeind)
  msf_time=(/msf_time/10^9/)
  delete(f1)
  msfa=rmMonAnnCycLLT(msf_time)
  printVarSummary(msfa)
  msfa_annual=month_to_annual(msfa(time|:,level|:,lon|:), 1)
 

;;;回归p场

  msfa_annual_rc1=regCoef_n(ipindex1,msfa_annual,0,0)  
  copy_VarCoords(msfa_annual(0,:,:), msfa_annual_rc1)

  msfa_annual_rc2=regCoef_n(ipindex2,msfa_annual,0,0)  
  copy_VarCoords(msfa_annual(0,:,:), msfa_annual_rc2)
  print("回归结束")
  
;;;

;;;计算趋势一致性
 rc1=regCoef_n(ispan(1,dimsizes(ipindex1),1),ipindex1,0,0)  
 rc2=regCoef_n(ispan(1,dimsizes(ipindex2),1),ipindex2,0,0)  
 print(rc2)
 trend_con=msfa_annual_rc2
 trend_con=(/rc2*msfa_annual_rc2/)


 printVarSummary(trend_con)

;;;



;;;显著性检验
  prob_msfa1=rc_test(msfa_annual_rc1)
  prob_msfa2=rc_test(msfa_annual_rc2)
;;;
print("检验结束")


;;;画图 

  gsn_define_colormap(wks, "BlueWhiteOrangeRed")
  ;;;画图
    res = True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnLeftString=rightstr
    res@gsnRightString="PC-1 regress MSF"
    ; res@lbLabelStrings=ispan(-6,6,1)
    ; res@cnFillPalette  = "BlueDarkRed18"
    res@cnLinesOn=True
    res@cnLevelSelectionMode ="ManualLevels"
    res@cnMinLevelValF = -0.8
    res@cnMaxLevelValF = 0.8
    res@cnLevelSpacingF = 0.1
    res@cnLineLabelFontHeightF=0.01
    res@cnFillOn = True 
    res@cnLineLabelsOn=False
    res@gsnContourNegLineDashPattern=1
    
    res@cnLineLabelsOn=True
    res@cnLineLabelBackgroundColor="Transparent"
    res@cnMonoFillScale=True
    res@cnInfoLabelOn=False
      
    res@lbOrientation="Horizontal"
    res@lbLabelBarOn=False
    res@tiYAxisString=""
    res@tmXTOn=False
    res@tmYROn=False
    res@tmXBMode="Explicit"
    res@tmXBValues=(/0,90,180,270,357.5/)
    res@tmXBLabels=(/"0","90~S~o~N~E","180","90~S~o~N~W","0"/)
    res@tmXBMinorOn=True
    res@tmXBMinorValues=ispan(0,360,10)
    res@tmYRMode="Automatic"
    
    
    res@vpHeightF=0.3
    res@vpWidthF=0.7
    
    ; plot=gsn_csm_pres_hgt_vector(wks,msfa_rc,uda_rc,wa_rc,res)
    plot=new(2,graphic)
    plot(0)=gsn_csm_pres_hgt(wks, msfa_annual_rc1, res)
    res@gsnRightString="PC-2 regress MSF"
    ; plot(1)=gsn_csm_pres_hgt(wks, msfa_annual_rc2, res)



    plot(1)=gsn_csm_pres_hgt(wks, msfa_annual_rc2, res)
    print("画图结束")

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
  ; res_pro@cnLevels = ispan(-6,6,1)
  res_pro@cnLineLabelsOn=False
  res_pro@tmYRMode = "Automatic"
  res_pro@cnInfoLabelOn=False
  ; res_pro@cnLineLabelBackgroundColor="Transparent"
  ; res_pro@cnLineThicknessF = 3.
  ; res_pro@cnFillOn        = True
 
  iplot=new(2,graphic)
 
  iplot(0)=gsn_csm_pres_hgt(wks,prob_msfa1,res_pro)
  iplot(1)=gsn_csm_pres_hgt(wks,prob_msfa2,res_pro)
 

  opt                      = True
  opt@gsnShadeFillType     = "pattern"
  opt@gsnShadeMid     = 17         ; stipple
  ; opt@gsnShadeHigh   = "green"
  opt@gsnShadeFillScaleF   = 0.2         ; add extra density
  opt@gsnShadeFillDotSizeF = 0.0      ; make dots larger
  do i=0,1
  iplot(i) = gsn_contour_shade(iplot(i), 0,0.05, opt)
end do



;;;  
  do i=0,1
  overlay(plot(i), iplot(i))
  end do

if eofnum.eq.0 then
return(plot(0))
end if

if eofnum.eq.1 then
return(plot(1))
end if
end 

;*******************************************************
;main program
;********************************************************
begin
 str=new(4,string)

 str(0)="ncep/20CR/msf_time_20cr_global_6--6.nc"
 str(1)="ncep/ncep1/msf_time_ncep1_global.nc"
 str(2)="era/era40/msf_time_era40_in_global.nc"
 str(3)="JRA-55/msf_time_jra55_global.nc"


rightstr=(/"20CR","ncep1","ERA-40&ERA_interium","JRA-55"/)
  plot_1=new(4,graphic)
  plot_2=new(4,graphic)
eofnum=0

wks=gsn_open_wks("pdf", "/mnt/f/share/era/data/所有msf与giss_全球平均温度回归趋势一致性")

do i=0,3
plot_1(i)=regress_msf(str(i),eofnum,wks,rightstr(i))
end do 

;;---Resources for the polyline  添加下垫面的陆地
  ployres                  = True          ; polyline mods desired
  ployres@gsLineThicknessF = 15.0            ; line thickness   
  ployres@gsLineColor      = "black"         ; color of lines
  ployres@gsLineDashPattern=15
 ;---Attach the polyline
  ploylevel=1000
  ploylon1=fspan(9, 39, 25)
  ploylon2=fspan(100, 149, 25)
  ploylon3=fspan(280, 315, 25)
  ploylevel1=conform_dims(dimsizes(ploylon1), ploylevel, 0)
  ploylevel2=conform_dims(dimsizes(ploylon2), ploylevel, 0)
  ploylevel3=conform_dims(dimsizes(ploylon3), ploylevel, 0)

  ployres@gsLineDashPattern=0
  dum1=new(4,graphic)
  dum2=dum1
  dum3=dum1

  do i=0,3
  dum1(i)= gsn_add_polyline(wks, plot_1(i),  ploylon1,ploylevel1,  ployres)
  ployres@gsLineDashPattern=16
  dum2(i)= gsn_add_polyline(wks, plot_1(i),  ploylon2,ploylevel2,  ployres)
  ployres@gsLineDashPattern=0
  dum3(i)= gsn_add_polyline(wks, plot_1(i),  ploylon3,ploylevel3,  ployres)
  end do
  
   pgres=True
   pgres@gsLineColor="red"
   pgres@gsLineThicknessF=4.0
   pgx1=(/150,250,250,150,150/)
   pgy1=(/950,950,150,150,950/)
   
   pgx2=(/40,110,110,40,40/)
   pgy2=(/950,950,150,150,950/)

    dumpg1=new(4,graphic)
    dumpg2=dumpg1
    do i=0,3
   dumpg1(i) = gsn_add_polyline(wks, plot_1(i), pgx1, pgy1, pgres)
   dumpg2(i)= gsn_add_polyline(wks, plot_1(i), pgx2, pgy2, pgres)
   end do

  pres=True
  pres@gsnPanelLabelBar=True
  pres@pmLabelBarWidthF=0.8
  gsn_panel(wks, plot_1, (/2,2/), pres)




end 