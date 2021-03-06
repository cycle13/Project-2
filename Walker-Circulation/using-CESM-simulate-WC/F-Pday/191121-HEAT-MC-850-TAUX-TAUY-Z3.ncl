;;;将每年每个月的数据分开
function month_to_month(u_heat) 
begin
    dim = dimsizes(u_heat)
    year =  dim(0)/12
    u_heat_mon = new((/12,year,dim(1),dim(2)/),typeof(u_heat))
    
    do i = 0,11,1
    u_heat_mon(i,:,:,:) = u_heat(i:dim(0)-1:12,:,:)
    end do
  return u_heat_mon
end 
begin
fils1  =  "/home/ys17-19/lsh/HEAT_MC_CP.cam.h0.25001-28912.nc"
fils2 = "/home/ys17-19/lsh/B2000_f19g16_CP_CTRL.cam.h0.25001-28912.nc"

f1 = addfile(fils1, "r")
f2 = addfile(fils2, "r")

 date  =  cd_calendar(f1->time, 1)

 timeind  =  ind(date.le.28912.and.date.ge.26001)



u_heat = f1->TAUX(timeind,:,:)
u_ct = f2->TAUX(timeind,:,:)

v_heat = f1->TAUY(timeind,:,:)
v_ct = f2->TAUY(timeind,:,:)

slp_heat = f1->Z3(timeind,{200},:,:)
slp_ct = f2->Z3(timeind,{200},:,:)

;;;得到每个月的值

   u_heat_mon = month_to_month(u_heat)
   u_ct_mon = month_to_month(u_ct)
;;;;

u_heat_mam = month_to_season(u_heat, "MAM")
u_ct_mam = month_to_season(u_ct, "MAM")

v_heat_mam = month_to_season(v_heat, "MAM")
v_ct_mam = month_to_season(v_ct, "MAM")

slp_heat_mam = month_to_season(slp_heat, "MAM")
slp_ct_mam = month_to_season(slp_ct, "MAM")


u_heat_mam_pa = dim_avg_n_Wrap(u_heat_mam(:,{-5:5},{150:210}), (/1,2/))

u_heat_mam_id = dim_avg_n_Wrap(u_heat_mam(:,{-5:5},{70:100}), (/1,2/))


u_ct_mam_pa = dim_avg_n_Wrap(u_ct_mam(:,{-5:5},{150:210}), (/1,2/))

u_ct_mam_id = dim_avg_n_Wrap(u_ct_mam(:,{-5:5},{70:100}), (/1,2/))

corr_heat = escorc_n(u_heat_mam_pa, u_heat_mam_id, 0, 0)

corr_ct = escorc_n(u_ct_mam_pa, u_ct_mam_id, 0, 0)

print("corr_heat="+corr_heat)
print("corr_ct="+corr_ct)

   ;;;
    x = dim_avg_n_Wrap(u_ct(:,{-5:5},{150:210}), (/1,2/))
    y = dim_avg_n_Wrap(u_ct(:,{-5:5},{70:100}), (/1,2/))

    mxlag    = 12
    x_Lead_y = esccr(x,y,mxlag)
    y_Lead_x = esccr(y,x,mxlag)    ; switch the order of the series

    ccr = new ( 2*mxlag+1, float)    
    ccr(0:mxlag-1) = y_Lead_x(1:mxlag:-1)  ; "negative lag", -1 reverses order
    ccr(mxlag:)    = x_Lead_y(0:mxlag)     ; "positive lag"

    wks=gsn_open_wks("pdf", "春季的IWC与PWC的超前滞后相关")

    res=True
    plot=gsn_csm_xy(wks, fspan(-12,12,25), ccr, res)

delete(plot)
delete(wks)
exit()

;;;计算每个月的相关系数

    u_heat_mon_pa = dim_avg_n_Wrap(u_heat_mon(:,:,{-5:5},{150:210}), (/2,3/))

    u_heat_mon_id = dim_avg_n_Wrap(u_heat_mon(:,:,{-5:5},{70:100}), (/2,3/))

    corr_heat_mon = escorc_n(u_heat_mon_id, u_heat_mon_pa, 1, 1)

    u_ct_mon_pa = dim_avg_n_Wrap(u_ct_mon(:,:,{-5:5},{150:210}), (/2,3/))

    u_ct_mon_id = dim_avg_n_Wrap(u_ct_mon(:,:,{-5:5},{70:100}), (/2,3/))

    corr_ct_mon = escorc_n(u_ct_mon_id, u_ct_mon_pa, 1, 1)
;;;


u_diff = dim_avg_n_Wrap(u_heat_mam, 0) - dim_avg_n_Wrap(u_ct_mam, 0)

v_diff = dim_avg_n_Wrap(v_heat_mam, 0) - dim_avg_n_Wrap(v_ct_mam, 0)

slp_diff = dim_avg_n_Wrap(slp_heat_mam, 0) - dim_avg_n_Wrap(slp_ct_mam, 0)

copy_VarCoords(u_heat(1,:,:), u_diff)
copy_VarCoords(v_heat(1,:,:), v_diff)
copy_VarCoords(slp_heat(1,:,:), slp_diff)


;;;画图

;;---------------画趋势图--------------------------------------
    wks=gsn_open_wks("pdf", "DIFF-HEAT-MC-TAUX-TAUY-Z3")
    res=True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnAddCyclic=True


    res@cnLineColors="Transparent"  ;
    res@lbLabelBarOn=True
    res@cnFillOn = True 
    res@cnLinesOn =False
    res@cnLineLabelsOn=False
    res@cnRasterSmoothingOn=True

    res@cnFillPalette = "BlRe"

    ; res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels

    ; res@cnMinLevelValF       =   -0.3
    ; res@cnMaxLevelValF       =   0.3
    ; res@cnLevelSpacingF      =  0.05

    res@tmXTOn=False
    res@tmYROn=False

    res@mpLimitMode           = "LatLon"
    res@mpMinLatF             = -30.0
    res@mpMaxLatF             = 30.0
    res@mpMinLonF             = 0.0
    res@mpMaxLonF             = 360.0
    res@mpCenterLonF          = 180.0

    res@mpShapeMode = "FreeAspect"
    res@vpWidthF = 0.6
    res@vpHeightF = 0.3

    ;;
     ;;;LineArrow
    res@gsnScalarContour        = True
    
    res@vcGlyphStyle             = "LineArrow"      ; turn on curly vectors
    ; res@vcGlyphStyle="CurlyVector"

    res@vcMinDistanceF           = 0.03           ; thin vectors
    ; res@vcMinMagnitudeF          =0.05
    ; res@vcRefMagnitudeF          = 0.6
    res@vcRefLengthF             = 0.04     ; define length of v
    res@vcRefAnnoOrthogonalPosF  = -1.0              ; move ref vector down -1.0在图的右上
    res@vcLineArrowThicknessF=1.0
    res@vcLineArrowHeadMaxSizeF=0.01
    res@vcLineArrowHeadMinSizeF=0.01
    res@vcVectorDrawOrder="PostDraw"

    ;;;CurlyVector
    ; res@vcLineArrowThicknessF=1.5
    ; res@vcMinFracLengthF=0.3
    ; res@vcMinDistanceF           = 0.015           ; thin vectors
    ; res@vcLineArrowThicknessF=1.0
    ; res@vcMinDistanceF           = 0.02          ; thin vectors
    ; res@vcMinMagnitudeF          =3.0
    ; res@vcRefAnnoOrthogonalPosF  = -1.0              ; move ref vector down -1.0在图的右上
    ;;;
    res@gsnLeftString = "Observation"
    plot = gsn_csm_vector_scalar_map(wks,u_diff,v_diff,slp_diff,res)
   
   draw(plot)
   frame(wks)
;;;;画直线图，每个月的情况

    res2 =True
    res2@tmXBMode = "Manual"
    res2@tmXBTickStartF = 1
    res2@tmXBTickEndF = 12
  
    res2@xyMonoMarkLineMode = True
    res2@xyMarkLineMode  = (/"MarkLines"/) 
    res2@xyMonoMarkLineMode = True
    res2@xyLineColors      = (/"black","pink"/)          ; change line color
    res2@xyMarkerColors = (/"black","pink"/) 
    
    wks2 = gsn_open_wks("pdf", "HEAT-MC-IWC-PWC-TAUX-corr")
    plotxy = gsn_csm_xy(wks2, ispan(1, 12, 1), (/corr_ct_mon,corr_heat_mon/), res2)

end




;;;
