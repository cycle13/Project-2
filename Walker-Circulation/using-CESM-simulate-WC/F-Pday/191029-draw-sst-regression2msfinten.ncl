;;;**********************************************************************
;;;计算三个环流的msf强度与海温的回归场
;;;2019.10.29
;;;by shuheng lin
;;;**********************************************************
function  rc_test(ssta_rc,id1,id2)
begin
   dim = dimsizes(id1)
   varname = getVarDimNames(id2)
  
   ;;有效自由度 
   r1_r = esacr(id1, 1)  
   r2_r = esacr(id2(latitude|:,longitude|:,year|:), 1)

   r1_o = r1_r(1)
   r2 = r2_r(:,:,1)
   f = dimsizes(r2)

   r1  = onedtond(r1_o, dimsizes(r2))

   v = dim*(/1-r1*r2/)/(/1+r1*r2/) 
 
   ssta_rc_new = onedtond(ssta_rc, dimsizes(ssta_rc))
   tval = sqrt(v-2)*(/ssta_rc_new/)/(sqrt(1- ssta_rc_new^2))

   df   = v-2
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
;;;;
begin
;;;读入HadiSST海温数据
  diri="/home/ys17-19/lsh/data/sst/"
  fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
  f1=addfile(fils1, "r")
  date=cd_calendar(f1->time, 1)

  timeind=ind(date.le.201212.and.date.ge.197901)
  
  sst=lonFlip(f1->sst(timeind,{60:-60},:))
  ssta=(/rmMonAnnCycTLL(sst)/)
  copy_VarCoords(sst, ssta)
  ssta=(/dtrend_msg_n(ispan(1,dimsizes(ssta&time),1),ssta,False,True,0)/)
  ; ssta_son=month_to_season(ssta_de, "SON")
  ; ssta_djf=month_to_season(ssta_de, "DJF")
  ssta_annual = month_to_annual(ssta, 1)
  ; ssta_s=(/ssta_son(0:54,:,:)+ssta_djf(1:,:,:)/)*0.5
  ; copy_VarCoords(ssta_son(0:54,:,:), ssta_s)
  delete(date)
  delete(timeind)
;;;读入msf的数据

  fils1  =  "/home/ys17-19/lsh/data/rea_msf/msf_time_era_global.nc"
  f1  =  addfile(fils1, "r") 
  date=cd_calendar(f1->time, 1)
  timeind=ind(date.le.201212.and.date.ge.197901)

  msf_time = f1->msf_time(:,:,timeind)

  msf_time = (/msf_time/10^9/)

  msf_time = (/dtrend_msg_n(ispan(1,dimsizes(msf_time&time),1),msf_time,False,True,2)/)

  msf_time =(/rmMonAnnCycLLT(msf_time)/)

  msf_time_annual = month_to_annual(msf_time(time|:,level|:,lon|:), 1)

  msf_pa_inten = dim_avg_n_Wrap(msf_time_annual(:,:,{150:210}),(/1,2/))
  msf_id_inten = dim_avg_n_Wrap(msf_time_annual(:,:,{70:100}),(/1,2/))
  msf_al_inten = dim_avg_n_Wrap(msf_time_annual(:,:,{310:340}),(/1,2/))
  delete(date)
  delete(timeind)
;;;

;;滑动平均，提取年代际变化信号
  msf_pa_inten = (/runave_n(msf_pa_inten, 9, 0, 0)/)
  msf_id_inten = (/-1*runave_n(msf_id_inten,9, 0, 0)/)
  msf_al_inten = (/runave_n(msf_al_inten, 9, 0, 0)/)
  ; ssta_annual = (/runave_n(ssta_annual,9, 0, 0)/)
;;

; ;;;回归sst场

  ssta_id_rc=regCoef_n(msf_id_inten,ssta_annual,0,0)  
  copy_VarCoords(ssta(0,:,:), ssta_id_rc)

  ssta_pa_rc=regCoef_n(msf_pa_inten,ssta_annual,0,0)  
  copy_VarCoords(ssta(0,:,:), ssta_pa_rc)

  ssta_al_rc=regCoef_n(msf_al_inten,ssta_annual,0,0)  
  copy_VarCoords(ssta(0,:,:), ssta_al_rc)
;;;

;;;相关系数
  rc_id = escorc_n(msf_id_inten, ssta_annual, 0, 0)
  rc_pa = escorc_n(msf_pa_inten, ssta_annual, 0, 0)
  rc_al = escorc_n(msf_al_inten, ssta_annual, 0, 0)
;;;

  
; ;;;回归u场,v场

;   ssta_rc=regCoef_n(ipindex2,ssta_s,0,0)  
;   copy_VarCoords(ssta_s(0,:,:), ssta_rc)

;   ua_rc=regCoef_n(ipindex2,ua_cold,0,0)  
;   copy_VarCoords(ua(0,:,:), ua_rc)

;   va_rc=regCoef_n(ipindex2,va_cold,0,0)  
;   copy_VarCoords(va(0,:,:), va_rc)

;;;显著性检验
  prob_id=rc_test(rc_id, msf_id_inten,ssta_annual)
  prob_pa=rc_test(rc_pa, msf_pa_inten, ssta_annual)
  prob_al=rc_test(rc_al, msf_al_inten, ssta_annual)

  ; prob_id=rc_test(ssta_id_rc)
  ; prob_pa=rc_test(ssta_pa_rc)
  ; prob_al=rc_test(ssta_al_rc)

 
  copy_VarCoords(ssta_id_rc, prob_id)
  copy_VarCoords(ssta_id_rc, prob_pa)
  copy_VarCoords(ssta_id_rc, prob_al)


; ;;;显著性检验
;   prob_ssta=rtest(ssta_rc,dimsizes(ssta_s&time),0)
;   prob_ua=rtest(ua_rc,dimsizes(ua_cold&time),0)
;   prob_va=rtest(va_rc,dimsizes(va_cold&time),0)
;   prob_ssta=where(prob_ssta.eq.0, prob_ssta@_FillValue, prob_ssta)
;   copy_VarCoords(ssta_rc, prob_ssta)
;   copy_VarCoords(ua_rc, prob_ua)
;   copy_VarCoords(va_rc, prob_va)
; ;;;



; ;;;风场的检验
;   ua_rc=where(prob_ua.le.0.05, ua_rc, ua_rc@_FillValue)
;   va_rc=where(prob_va.le.0.05, va_rc, va_rc@_FillValue)
;   printVarSummary(ua_rc)
;   printVarSummary(va_rc)
; ;;;



;;;画图
wks = gsn_open_wks("pdf", "各环流强度指数回归sst")
  ; gsn_define_colormap(wks, "BlueWhiteOrangeRed")
  gsn_define_colormap(wks, "BlRe")
  
  res=True
  res@gsnDraw=False
  res@gsnFrame=False
  res@gsnAddCyclic=False
  res@gsnScalarContour        = True
  res@cnLineColors="Transparent"  ;让填充是渐变的还是分隔的，colorbar是渐变还是间隔
  res@cnFillOn = True 
  res@cnLinesOn =False
  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels
  res@cnMinLevelValF       =   -2.0
  res@cnMaxLevelValF       =   2.0
  res@cnLevelSpacingF      =  0.5
  res@lbLabelBarOn=False
  res@cnLineLabelsOn =False
  
  ; res@cnMinLevelValF       =   -0.1
  ; res@cnMaxLevelValF       =   0.1
  ; res@cnLevelSpacingF      =  0.01
  
  ; res@cnMinLevelValF       =   -0.02
  ; res@cnMaxLevelValF       =   0.02
  ; res@cnLevelSpacingF      =  0.005

  res@lbOrientation = "Horizontal"

  res@mpLimitMode           = "LatLon"
  res@mpMinLatF             = min(ssta&latitude)
  res@mpMaxLatF             = max(ssta&latitude)
  res@mpMinLonF             = min(ssta&longitude)
  res@mpMaxLonF             = max(ssta&longitude)
  res@mpCenterLonF          =avg(ssta&longitude)
  res@mpFillDrawOrder = "PostDraw"

  res@tmXTOn=False
  res@tmYROn=False

  res@vcRefMagnitudeF          = 3.0          ; define vector ref mag
  res@vcRefLengthF             = 0.04         ; define length of vec ref
  res@vcGlyphStyle             = "LineArrow"      ; turn on curly vectors
  res@vcMinDistanceF           = 0.008          ; thin vectors
  res@vcRefAnnoOrthogonalPosF  = -1.0              ; move ref vector down -1.0在图的右上角
  res@mpShapeMode = "FreeAspect"
  res@vpWidthF = 0.6
  res@vpHeightF = 0.4
   
   plot = new(3,graphic)
   res@gsnLeftString = "indian cell"
   plot(0) = gsn_csm_contour_map(wks, ssta_id_rc, res)
   res@gsnLeftString = "pacific cell"
   plot(1) = gsn_csm_contour_map(wks, ssta_pa_rc, res)
   res@gsnLeftString = "atlantic cell"
   plot(2) = gsn_csm_contour_map(wks, ssta_al_rc, res)
 
;;;打点
  res_pro=True
  res_pro@gsnDraw=False
  res_pro@gsnFrame=False
  res_pro@cnFillOn = True

  res_pro@cnLevelSelectionMode = "ExplicitLevels"
  res_pro@cnLevels = (/0,0.05/)
  res_pro@lbLabelBarOn = False

  ; res_pro@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels
  ; res_pro@cnMinLevelValF       =   0
  ; res_pro@cnMaxLevelValF       =   0.05
  ; res_pro@cnLevelSpacingF      =  0.05

  res_pro@cnLinesOn=True
  res_pro@cnMonoLineColor =False
  res_pro@cnLineColors = ((/"Transparent","White","Transparent"/))

  res_pro@cnMonoFillPattern = True
  res_pro@cnFillPattern = 17
  res_pro@cnFillDotSizeF = 0.0045
  res_pro@cnMonoFillColor = False
  res_pro@cnFillColors = (/"Transparent","White","Transparent"/)
  ; res_pro@cnLevels = ispan(-6,6,1)
  res_pro@cnLineLabelsOn=False
  res_pro@tmYRMode = "Automatic"
  res_pro@cnInfoLabelOn=False
  ; res_pro@cnLineLabelBackgroundColor="Transparent"
  ; res_pro@cnLineThicknessF = 3.
  ; res_pro@cnFillOn        = True
  iplot = new(3,graphic)

  iplot(0)=gsn_csm_contour(wks,prob_id,res_pro)
  iplot(1)=gsn_csm_contour(wks,prob_pa,res_pro)
  iplot(2)=gsn_csm_contour(wks,prob_al,res_pro)
  

do i=0,2
overlay(plot(i), iplot(i))
end do

pres = True
pres@gsnPanelLabelBar = True
gsn_panel(wks, plot, (/2,2/), pres)
end


