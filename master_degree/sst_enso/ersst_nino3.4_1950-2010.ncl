begin 
m=""+ispan(1950,2010,1)+""
diri="/mnt/f/share/ersst/"
;  fils1=systemfunc("ls "+diri+"MMEAN0089*.nc")
;**************************************************
 ;批量读取nc文件，by lin
;*************************************************
fils=new((/61,12/),string)
do i=0,60
fils1=systemfunc("ls "+diri+"ersst."+m(i)+"*"+".nc")
fils(i,:)= fils1
end do
fils_new=onedtond(fils, 61*12)

; fileh(456)="/mnt/f/share/ersst/ersst.201701.nc" 
; fileh(0:455)=fils_new
f1=addfiles(fils_new,"join")
ssta=f1[:]->ssta
printVarSummary(ssta)
f2=addfile(fils_new(456),"r")
 
 lon=f2->lon(:)
 lat=f2->lat(:)
 latind1=ind(lat.eq.-6)
 latind2=ind(lat.eq.6)
 lonind1=ind(lon.eq.190)
 lonind2=ind(lon.eq.240)

 ; ssta_area=ssta(:,0,latind1:latind2,lonind1:lonind2)
  ssta_area=dtrend_n(ssta(:,0,latind1:latind2,lonind1:lonind2),True,0)
 copy_VarCoords(ssta(:,0,latind1:latind2,lonind1:lonind2), ssta_area)
 xo=ispan(190,240,1)
 yo=ispan(-6,6,1)
 ssta_int=linint2_Wrap(ssta_area&lon, ssta_area&lat, ssta_area, False, xo, yo, 0)
 LAT=ssta_int&LAT
 LON=ssta_int&LON
 nino3_4=dim_avg_n_Wrap(ssta_int(:,ind(LAT.eq.-5):ind(LAT.eq.5),ind(LON.eq.190):ind(LON.eq.240)), (/1,2/))
 printVarSummary(nino3_4)
 
 opt=diri+"nino3_4_1950_2010.ascii"

 asciiwrite(opt, sprintf ("%5.2f,", nino3_4))
   
end 
