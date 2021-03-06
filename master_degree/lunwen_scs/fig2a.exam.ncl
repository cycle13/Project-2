;draw_msf_hov
load "/mnt/d/ncl/lib/ncarg/nclscripts/csm/taylor_diagram.ncl"   
load "/mnt/d/ncl/lib/ncarg/nclscripts/csm/taylor_diagram_lin_scs.ncl"
load "/mnt/d/ncl/Dot-Matrix-master/WCHAR.ncl" ; All related function tar into this lib 
;
begin
;画时间序列图的时候，把BCC-CSM1-1给去掉

models=(/"BNU-ESM","CanESM2", "CESM1-BGC", "CESM1-CAM5","CMCC-CMS","FIO-ESM","GFDL-ESM2G","GFDL-ESM2M","GISS-E2-H",\
    "GISS-E2-H-CC","GISS-E2-R","GISS-E2-R-CC","HadGEM2-AO","HadGEM2-CC",\
    "HadGEM2-ES","MIROC-ESM-CHEM","NorESM1-ME","20cr",\
    "era","jra55","MERRA","ncep1","ncep2"/)
;;;

rea=(/"20cr","era","jra55","MERRA","ncep1","ncep2"/)
; models=(/"BNU-ESM"/)
dim=dimsizes(models)

; msf_total=new((/dim,12,144/), float)
; msf_total=new((/dim,12,57/), float)
; msf_total=new((/dim,12,85/), float)
msf_total=new((/dim,12,93/), float)
; msf_total=new((/dim,12,105/), float)


yearstart=197901
yearend=200812  
year1=1979
year2=2008
; p  = 0.975
p=0.95
year=year2-year1+1
locationxi_rea=new((/dim,year/), float)
;******************************************************************************************************
;循环读入数据
;******************************************************************************************************
do i=0,dimsizes(models)-1
 ; model="CanESM2"
 model=models(i)
 print("************************"+model+"*****************************")
 if any(rea.eq.model) then 
 diri="/mnt/f/share/rea_msf/"
 fils1=systemfunc("ls "+diri+"msf_time_"+model+"_global_new.nc")


;;;********************************************* 
    f1=addfile(fils1, "r")
    date=cd_calendar(f1->time, 1)
    timeind=ind(date.le.yearend.and.date.ge.yearstart)
    msf_time_r= f1->msf_time(:,{60:290},timeind)
    delete(f1)

    msf_time_r=(/msf_time_r/10^9/)
    msf_time=tofloat(msf_time_r)
    copy_VarMeta(msf_time_r, msf_time)
    printVarSummary(msf_time)
    delete(msf_time_r)
    delete(msf_time&time)
    msf_time&time=date(timeind)
    delete(date)
    ; msf_mean=level_mean(msf_time(:,:,:))
    ; msf_mean=dim_avg_n_Wrap(msf_time(time|:,level|:,lon|:),1)
    msf_mean=msf_time
    printVarSummary(msf_mean)
    delete(msf_time)
    delete(timeind)
  ;;;******************************************************

 else
  diri1="/mnt/f/share/CMIP5/msf_history/"
  diri2="/mnt/f/share/CMIP5/msf_rcp45/"

  fils1=systemfunc("ls "+diri1+"msf_time_"+model+"_history_r1i1p1_197901-200512.nc")
  fils2=systemfunc("ls "+diri2+"msf_time_"+model+"_rcp45_r1i1p1_200601-201212.nc")

  yearstart1=197901
  yearend1=200512

  yearstart2=200401   ;;;因为存在200512开始的
  yearend2=200812

  year1=1979
  year2=2008
  fils=new(2,string)
  fils(0)=fils1
  fils(1)=fils2

;;;********************************************* 
    f=addfiles(fils, "r")
    f1=addfile(fils1, "r")
    f2=addfile(fils2, "r")

    date=cd_calendar(f[:]->time, 1)
    date1=cd_calendar(f1->time, 1)
    date2=cd_calendar(f2->time, 1)
    
    timeind=ind(date.ge.197901.and.date.le.200812)

    timeind1=ind(date1.le.yearend1.and.date1.ge.yearstart1)
    timeind2=ind(date2.le.yearend2.and.date2.ge.yearstart2)
 
    delete([/date1 ,date2/])
    year=year2-year1+1
    msf_time1_r=f1->msf_time(:,{60:290},timeind1)
    msf_time1=tofloat(msf_time1_r/10^9)
    copy_VarMeta(msf_time1_r, msf_time1)
    delete(msf_time1_r)
    delete(f1)
 
    printVarSummary(msf_time1)
    dim_data=dimsizes(msf_time1)
    msf_time=new((/dim_data(0),dim_data(1),year*12/),typeof(msf_time1))
    msf_time2_r=f2->msf_time(:,{60:290},timeind2)
    msf_time2=tofloat(msf_time2_r/10^9)
    copy_VarMeta(msf_time2_r, msf_time2)
    delete(msf_time2_r)
    delete(f2)

    printVarSummary(msf_time2)
    msf_time(:,:,0:dimsizes(timeind1)-1)=msf_time1
    msf_time(:,:,dimsizes(timeind1):)=msf_time2
    msf_mean=msf_time
    printVarSummary(msf_mean)
    delete(msf_time)
    delete(msf_time1)
    delete(msf_time2)
    delete(timeind)
    delete([/timeind1,timeind2/])
end if

    msf_clm=dim_avg_n_Wrap(msf_mean, 2)
    msf_total(i,:,:)=msf_clm(:,:)
    delete(msf_clm)
end do

msf_cmip=dim_avg_n_Wrap(msf_total(0:dim-7,:,:), 0)
printVarSummary(msf_cmip)
; msf_mre=msf_total(dim-1,:,:)
msf_mre=dim_avg_n_Wrap(msf_total(dim-6:dim-1,:,:),0)
printVarSummary(msf_mre)


pa_cor=new(dim+1,float)
ratio=new(dim+1,float)

;;权重系数
plev=msf_cmip&level
psfc=1013.0
ptop=min(plev)
dp   = dpres_plevel_Wrap(plev, psfc, ptop, 0)  ; dp(30)
printVarSummary(dp)
w=dp/sum(dp)
printVarSummary(w)

;;;

do i=0,dim-1
  taylor_stat = taylor_stats(msf_total(i,:,:),msf_mre,w,0)
  pa_cor(i)=taylor_stat(0)
  ratio(i)=taylor_stat(1)
  delete(taylor_stat)
end do

  taylor_stat = taylor_stats(msf_cmip,msf_mre,w,0)
  pa_cor(dim)=taylor_stat(0)
  ratio(dim)=taylor_stat(1)
  delete(taylor_stat)

;;pattern_cor
ncase=dim+1
cc=new((/ncase,1/),typeof(pa_cor))
;;ratio
ra=new((/ncase,1/),typeof(ratio))
;;
cc=pa_cor
ra=ratio
Markers=new(ncase,integer)
Markers=16
Colors=new(ncase,string)
Colors="white"
;**********************************
; create plot
;**********************************02


  ty_opt   = True                           ; taylor diagram with options
  ty_opt@taylorDraw   =False
  ty_opt@taylorFrame  =False
  ty_opt@Markers       = Markers         ; make all solid fill

  ty_opt@Colors        = Colors          
  ty_opt@varLabels     = ""
  ty_opt@caseLabels    = ""
  ty_opt@markerTxYOffset = 0.02                    ; offset btwn marker & label
  ty_opt@varLabelsYloc = 1.5                ; Move location of variable labels [default 0.45]
  ty_opt@caseLabelsFontHeightF = 0.14       ; make slight larger   [default=0.12 ]
  ty_opt@varLabelsFontHeightF  = 0.011      ; make slight smaller  [default=0.013]
 
  ty_opt@tiMainString  = "MSF"           ; title
  ty_opt@stnRad        = (/ 0.5, 1.5 /)     ; additional standard radii
  ty_opt@ccRays        = (/ 0.85, 0.95 /)     ; correllation rays
  ty_opt@centerDiffRMS = True               ; RMS 'circles'

  wks   = gsn_open_wks("pdf", "/mnt/f/share/era/data/scs_fig_exam.2a")
  plot  = taylor_diagram_lin(wks,ra,cc,ty_opt)


;;***********************************************************************
;;;添加注释
;;;**********************************************************************
alfa= ispan(1,17,1)
labels2= alfa + ":" + (/"BNU-ESM","CanESM2", "CESM1-BGC", "CESM1-CAM5","CMCC-CMS","FIO-ESM","GFDL-ESM2G","GFDL-ESM2M","GISS-E2-H",\
    "GISS-E2-H-CC","GISS-E2-R","GISS-E2-R-CC","HadGEM2-AO","HadGEM2-CC",\
    "HadGEM2-ES","MIROC-ESM-CHEM","NorESM1-ME"/)


    txres2               = True
    txres2@txFont = "times-roman"
    txres2@txFontHeightF = 0.010
    txres2@txFontColor="black"
    txres2@txJust="TopLeft"

    txres2@txFontThicknessF=5.0
    txres2@txFontHeightF = 0.015
    txres2@txFontColor="black"

     gsn_text_ndc (wks,"CMIP5",0.72,0.94,txres2)

  dim2=dimsizes(labels2)
  ytxt2=fspan(0.3, 0.9, dim2)
  ytxt2=ytxt2(::-1)
  xtxt=0.72
  txres2@txFontHeightF = 0.015
  txres2@txFontColor="black"
  do i=0,dim2-1
  gsn_text_ndc (wks,labels2(i),xtxt,ytxt2(i),txres2)
  end do

 ;;;;再分析的注释
     index_maker=(/2,15,5,6,7,8,16/)
  labels3=(/"20CR","ERA-Interium","JRA55","MERRA","NCEP1","NCEP2","MME"/)
  xleg = 0.90
  xtxt_rea = 0.92  ; legend markers
  yleg = fspan(0.65, 0.9, 7)
  yleg=yleg(::-1)
  ytxt_rea = yleg  ; strings.

 do i=0,6
  gsres               = True
  gsres@gsMarkerIndex = index_maker(i)         ; Use filled dots for markers.
  if i.eq.6 then 
  gsres@gsMarkerColor      = "green"
  else
  gsres@gsMarkerColor      = "red"
end if
  gsres@gsMarkerThicknessF = 0.015
  gsres@gsMarkerSizeF=10
   
; Add marker and text for the legend.
  gsn_polymarker_ndc(wks, xleg,yleg(i),gsres)
   txres2@txJust="CenterLeft"
   if i.eq.6 then
    txres2@txFontThicknessF=5.0
    txres2@txFontHeightF = 0.015
   txres2@txFontColor="green"
   else
    txres2@txFontColor="red"
  end if
  gsn_text_ndc      (wks,labels3(i),xtxt_rea,ytxt_rea(i),txres2)
end do
  
  
  txres2@txFontColor="red"
  txres2@txFontHeightF = 0.015
  txres2@txJust="TopLeft"
  gsn_text_ndc (wks,"Reanalysis",0.90,0.94,txres2)


   
  txres2@txFontColor="black"
  txres2@txFontHeightF = 0.03
  txres2@txJust="TopLeft"
  gsn_text_ndc (wks,"a",0.1,0.95,txres2)
  ; drawNDCGrid(wks)


  ;;;;添加中文注释
    fontres=True
    fontres@FontQuality="High"
    fontres@fontAngleF=90
    fontres@fontSize=14
    fontres@fontNDC=True

    fontX(wks,plot, "标准偏差", 0.04,0.6, fontres)
    fontres@fontAngleF=-45
    fontres@fontNDC=False
    fontX(wks,plot, "相关系数", 1.30,1.30, fontres)




;;;;************************************************************************************
draw(plot)
frame(wks)

end 
  