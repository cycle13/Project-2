  begin
;;读入数据
; model_name = (/"FGOALS-g3" , "GISS-E2-1-H",  "MIROC6", "NorCPM1", "UKESM1-0-LL",\
; "ACCESS-ESM1-5",  "CanESM5" , "E3SM-1-0"  ,    "GFDL-CM4"     ,"HadGEM3-GC31-LL" , "MIROC-ES2L",  "NorESM2-LM" ,\
; "AWI-CM-1-1-MR", "CESM2",  "EC-Earth3"  , "GFDL-ESM4"  ,"MPI-ESM1-2-HR" ,"CC-CSM2-MR",\
;  "CESM2-WACCM" , "EC-Earth3-Veg",  "GISS-E2-1-G", "IPSL-CM6A-LR" ,"MRI-ESM2-0","SAM0-UNICON",\
; "BCC-ESM1","CNRM-CM6-1","FGOALS-f3-L","GISS-E2-1-G-CC","MCM-UA-1-0","NESM3"/)

; model_name = (/"CESM2-WACCM" , "EC-Earth3-Veg",  "GISS-E2-1-G", "IPSL-CM6A-LR" ,"MRI-ESM2-0","SAM0-UNICON",\
; "BCC-ESM1","CNRM-CM6-1","FGOALS-f3-L","GISS-E2-1-G-CC","MCM-UA-1-0","NESM3"/)


; model_name = (/"ACCESS-CM2","ACCESS-ESM1-5", "BCC-ESM1",\
;               "CAMS-CSM1-0","CanESM5","CESM2","CESM2-WACCM","CNRM-CM6-1","CNRM-ESM2-1"\
;    , "E3SM-1-0", "EC-Earth3","EC-Earth3-Veg","FGOALS-f3-L",  "FGOALS-g3", \
;   "GFDL-ESM4",    "GISS-E2-1-G",  "GISS-E2-1-G-CC",   "GISS-E2-1-H"\
;         ,"HadGEM3-GC31-LL","IPSL-CM6A-LR",   "MCM-UA-1-0","MIROC6", \
;         "MIROC-ES2L","MPI-ESM1-2-HR","MRI-ESM2-0","NESM3","NorCPM1",  "NorESM2-LM","SAM0-UNICON","UKESM1-0-LL"/)

model_name = (/"NorESM2-LM"/)

dim_model = dimsizes(model_name)
do i = 0,dim_model-1
;;;;
    model = model_name(i)

    print("*******************start calculate"+" "+model+"**********************************************")
    diri_output="/home/yangsong3/data-observation/linshh/CMIP6-derived/vd/1850-1949/"
    
    yearstart = 185001
    yearend = 194912

    fils1 := systemfunc("ls /home/yangsong3/data-observation/cmip6/"+model+"/historical/uv_fixed/ua_Amon_"+model+"_historical_"+"*")
    fils2 := systemfunc("ls /home/yangsong3/data-observation/cmip6/"+model+"/historical/uv_fixed/va_Amon_"+model+"_historical_"+"*")

    f1=addfiles(fils1, "r")
    f2=addfiles(fils2, "r")

    time=f1[:]->time    ;;;这里用了20cr的time，因为jra的time是一个个来的
    date:=cd_calendar(time, 1)


    timeind:=ind(date.le.yearend.and.date.ge.yearstart)
    time_r = time(timeind)
    print(date(timeind))

    print("读入风场")
    plev := doubletofloat(f1[0]->plev)

    z0=(/1000.0,925.0,850.0,700.0,600.0,500.0,400.0,300.0,250.0,150.0,100.0/)*100.0

    levind=get1Dindex(plev,z0)
  

    uwnd := f1[:]->ua(timeind,levind,:,:)  ;;;195801-201212
    vwnd := f2[:]->va(timeind,levind,:,:)  ;;;
    
    delete(uwnd&plev)
    delete(vwnd&plev)
    uwnd!1="level"
    vwnd!1="level"
    printVarSummary(uwnd)
    
    uwnd&level :=(/plev(levind)/100.0/)
    vwnd&level :=(/plev(levind)/100.0/)
    delete(levind)

    uwnd&level@units  = "hPa"
    vwnd&level@units  = "hPa"
    ; print(uwnd&level)
    delete(f1)
    delete(f2)

    
   ;;;interp missing value
     print("****************interp missing value*********************")
       
    ;******************************************************************
    ; use poisson_grid_fill to fill missing value
    ;******************************************************************
    nscan = 1500           ; usually *much* fewer
    eps   = 0.001            ; variable depended
    gtype = False            ; "gendat" does not generate cyclic fields
    guess = 0                ; use zonal means
    relc  = 0.6              ; standard relaxation coef
    opt   = 0
    
    poisson_grid_fill(uwnd, gtype, guess, nscan, eps, relc, opt)
    
    poisson_grid_fill(vwnd, gtype, guess, nscan, eps, relc, opt)
      
   print("*********************开始计算辐散风******************************")  
    vrdvx=uv2vrdvF(uwnd,vwnd)
    ; vrdvx=uv2dv_cfd(uwnd, vwnd, uwnd&lat, vwnd&lon, 0)
    uvd=dv2uvF(vrdvx(1,:,:,:,:))
    delete(vrdvx)
    ; ud=uvd(0,:,:,:,:)
    vd=uvd(1,:,:,:,:)  ;;;time lev,lat,lon
    delete(uvd)
    vd!0="time"
    vd!1="level"
    vd!2="lat"
    vd!3="lon"
    copy_VarCoords(vwnd, vd)
    copy_VarAtts(vwnd, vd)
    printVarSummary(vd)
    delete(uwnd)
    delete(vwnd)
     
    dim = dimsizes(vd)
    ntime = dim(0)
    nlev = dim(1)
    nlat = dim(2)
    nlon = dim(3)
    
    print("***************开始写nc文件****************************")
;*********************************************写成nc文件,注意坐标变量之间的dimension也要命名。
    diro=diri_output
    filo1="vd_"+model+"_history_r1i1p1f1_185001-194912.nc"
    system("/bin/rm -f "+diro + filo1+"")
    setfileoption("nc","Format","LargeFile")
    fout=addfile(diro + filo1,"c")
    setfileoption(fout,"DefineMode",True)
   ;======================================文件名
    fAtt               = True            ; assign file attributes
    fAtt@title         = "CMIP6 historical run Meridional Divergence wind"    
    fAtt@creation_date = systemfunc("date")
    fileattdef( fout, fAtt)            ; copys file attributes    
    ;----------------------------坐标变量的定义
    dimnames=(/"time","level","lat","lon"/)
    dimsize=(/ntime,nlev,nlat,nlon/)
    dimunlim=(/False,False,False,False/)
    filedimdef(fout, dimnames, dimsize, dimunlim)
 ;-----------------------------定义变量名，类型和维数
    filevardef(fout, "time",typeof(vd&time), (/"time"/))
    filevardef(fout, "level",typeof(vd&level), (/"level"/))
    filevardef(fout, "lat", typeof(vd&lat),(/"lat"/))
    filevardef(fout, "lon", typeof(vd&lon),(/"lon"/))

   
    filevardef(fout, "vd", typeof(vd),(/"time","level","lat","lon"/))

   
    filevarattdef(fout, "level", vd&level)
    filevarattdef(fout, "lat", vd&lat)
    filevarattdef(fout, "lon", vd&lon)
    filevarattdef(fout, "time", time_r)
    filevarattdef(fout, "vd", vd)
 
    
    setfileoption(fout,"DefineMode",False)


    fout->time=(/time_r/)
    fout->level=(/vd&level/)
    fout->lat=(/vd&lat/)
    fout->lon=(/vd&lon/)
    fout->vd = (/vd/)
    delete(vd)
   delete(time_r)
   delete(time)
 print("********************************finish calculate"+" "+model+"************************************")
 end do 

end 



