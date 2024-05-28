function h5_data_get,file_name,dataset_name
  file_id=h5f_open(file_name)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro omi_no2_average_calculating
  ;输入输出路径设置
  start_time=systime(1)
  in_path='O:/coarse_data/chapter_2/NO2/'
  out_path='O:/coarse_data/chapter_2/NO2/average/'
  dir_test=file_test(out_path,/directory)
  if dir_test eq 0 then begin
    file_mkdir,out_path
  endif
  filelist=file_search(in_path,'*NO2*.he5')
  file_n=n_elements(filelist)
  group_name='/HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/'
  target_dataset='ColumnAmountNO2TropCloudScreened'
  dataset_name=group_name+target_dataset
  
  ;月份存储数组初始化
  data_total_month=fltarr(1440,720,12)
  data_valid_month=fltarr(1440,720,12)
  data_avr_month=fltarr(1440,720,12)
  
  ;季节存储数组初始化
  data_total_season=fltarr(1440,720,4)
  data_valid_season=fltarr(1440,720,4)
  data_avr_season=fltarr(1440,720,4)
  
  ;处理年份设置、年份存储数组初始化
  year_temp=fix(strmid(file_basename(filelist),19,4))
  year_start=min(year_temp)
  year_n=(max(year_temp)-year_start)+1
  data_total_year=fltarr(1440,720,year_n)
  data_valid_year=fltarr(1440,720,year_n)
  data_avr_year=fltarr(1440,720,year_n)
  
  for file_i=0,file_n-1 do begin
    ;判定目标数据集是否存在，实际处理时可能会遇到某个文件中不存在目标数据集的情况
    read_mark=0
    file_id=h5f_open(filelist[file_i])
    dataset_num=h5g_get_nmembers(file_id,group_name)
    group_id=h5g_open(file_id,group_name)
    for dataset_i=0,dataset_num-1 do begin
      dataset_name_temp=h5g_get_member_name(file_id,group_name,dataset_i)
      if dataset_name_temp eq target_dataset then begin
        read_mark=1
      endif
    endfor
    h5g_close,group_id
    h5f_close,file_id

    ;月、季、年结果累加，有效次数累加
    if read_mark eq 1 then begin
      print,filelist[file_i]
      data_temp=h5_data_get(filelist[file_i],dataset_name)
      ;help,data_temp
      data_temp=((data_temp gt 0.0)*data_temp/!const.NA)*(10.0^10.0);转mol/km2
      data_temp=rotate(data_temp,7)
      
      layer_i=fix(strmid(file_basename(filelist[file_i]),24,2))-1
      data_total_month[*,*,layer_i]=data_total_month[*,*,layer_i]+data_temp
      data_valid_month[*,*,layer_i]=data_valid_month[*,*,layer_i]+(data_temp gt 0.0)
      
      season_pos=[3,3,0,0,0,1,1,1,2,2,2,3]
      season_i=season_pos[layer_i]
      data_total_season[*,*,season_i]=data_total_season[*,*,season_i]+data_temp
      data_valid_season[*,*,season_i]=data_valid_season[*,*,season_i]+(data_temp gt 0.0)
      
      year_i=fix(strmid(file_basename(filelist[file_i]),19,4))-year_start
      data_total_year[*,*,year_i]=data_total_year[*,*,year_i]+data_temp
      data_valid_year[*,*,year_i]=data_valid_year[*,*,year_i]+(data_temp gt 0.0)
    endif else begin
      print,'The file '+filelist[file_i]+'has no the target dataset.'
    endelse
  endfor
  
  ;均值计算
  data_valid_month=(data_valid_month gt 0.0)*data_valid_month+(data_valid_month eq 0.0)*(1.0)
  data_avr_month=data_total_month/data_valid_month
  
  data_valid_season=(data_valid_season gt 0.0)*data_valid_season+(data_valid_season eq 0.0)*(1.0)
  data_avr_season=data_total_season/data_valid_season
  
  data_valid_year=(data_valid_year gt 0.0)*data_valid_year+(data_valid_year eq 0.0)*(1.0)
  data_avr_year=data_total_year/data_valid_year
  
  month_out=['01','02','03','04','05','06','07','08','09','10','11','12']
  season_out=['spring','summer','autumn','winter']
  
  geo_info={$
    MODELPIXELSCALETAG:[0.25,0.25,0.0],$
    MODELTIEPOINTTAG:[0.0,0.0,0.0,-180.0,90.0,0.0],$
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}
  
  ;依次输出月均、季均、年均Geotiff结果
  for month_i=0,11 do begin
    out_name=out_path+'month_avr_'+month_out[month_i]+'.tiff'
    write_tiff,out_name,data_avr_month[*,*,month_i],/float,geotiff=geo_info    
    print,'The output of '+out_name+' has been completed.'
  endfor
  
  for season_i=0,3 do begin
    out_name=out_path+'season_avr_'+season_out[season_i]+'.tiff'
    write_tiff,out_name,data_avr_season[*,*,season_i],/float,geotiff=geo_info
    print,'The output of '+out_name+' has been completed.'
  endfor
  
  for year_i=0,year_n-1 do begin
    out_name=out_path+'year_avr_'+strcompress(string(year_start+year_i),/remove_all)+'.tiff'
    write_tiff,out_name,data_avr_year[*,*,year_i],/float,geotiff=geo_info
    print,'The output of '+out_name+' has been completed.'
  endfor
  
  ;输出年均ASCII结果
  for year_i=0,year_n-1 do begin
    out_name=out_path+'year_avr_'+strcompress(string(year_start+year_i),/remove_all)+'.txt'
    openw,1,out_name
    printf,1,'lon,lat,no2'
    for data_line_i=0,719 do begin
      out_lat=89.875-(0.25*data_line_i)
      for data_col_i=0,1439 do begin
        out_lon=-179.875+(0.25*data_col_i)
        printf,1,out_lon,out_lat,data_avr_year[data_col_i,data_line_i,year_i],format='(3(F0.4,:,","))'
      endfor
    endfor
    print,'The ASCII output of '+out_name+' has been completed.'
    free_lun,1
  endfor
  
  end_time=systime(1)
  print,'Processing is end, the totol time consuming is:'+strcompress(string(end_time-start_time))+' s.'
end