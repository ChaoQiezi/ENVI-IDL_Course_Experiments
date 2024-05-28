function hdf4_data_get,file_name,sds_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,data
end

function hdf4_attdata_get,file_name,sds_name,att_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  att_index=hdf_sd_attrfind(sds_id,att_name)
  hdf_sd_attrinfo,sds_id,att_index,data=att_data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,att_data
end

pro mod04_nearest_point_value_extracting
  ;程序功能：从modis-mod04气溶胶数据集中提取出特定经纬度点位的产品结果
  ;待提取点位坐标
  extract_lon=[116.40,121.47,104.06]
  extract_lat=[39.90,31.23,30.67]
  point_name=['Beijing','Shanghai','Chengdu']
  point_n=n_elements(point_name)
  data_path='O:/coarse_data/chapter_1/MODIS_2018_mod04_3k/'
  file_list=file_search(data_path,'*.hdf')
  file_n=n_elements(file_list)
  for point_i=0,n_elements(point_name)-1 do begin    
    out_file=data_path+'point_value_'+point_name[point_i]+'.txt'
    openw,1,out_file
    ;多文件循环处理
    for file_i=0,file_n-1 do begin
      out_date=strmid(file_basename(file_list[file_i]),10,7)
      date=fix(strmid(file_basename(file_list[file_i]),14,3))
      out_year=fix(strmid(file_basename(file_list[file_i]),10,4))
      date_julian=imsl_datetodays(31,12,out_year-1) ;IMSL相关的函数说明在ENVI安装目录../Exelis/IDL85/help/pdf/advmathstats.pdf中
      imsl_daystodate,date_julian+date,day,month,year
      out_month=month
      out_day=day

      ;读取经纬度、气溶胶数据集和属性数据      
      modis_lon_data=hdf4_data_get(file_list[file_i],'Longitude')
      modis_lat_data=hdf4_data_get(file_list[file_i],'Latitude')
      modis_aod_data=hdf4_data_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean')
      scale_factor=hdf4_attdata_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean','scale_factor')
      fill_value=hdf4_attdata_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean','_FillValue')            
      modis_aod_data=(modis_aod_data ne fill_value[0])*modis_aod_data*scale_factor[0]

      ;最小距离像元位置（下标）计算
      lon_minus=abs(modis_lon_data-extract_lon[point_i])
      lat_minus=abs(modis_lat_data-extract_lat[point_i])
      distance=((lon_minus^2)+(lat_minus^2))^0.5
      min_pos=where(distance eq min(distance))
      
;      lt_pos=where(distance lt 0.1,count)      
;      for count_i=0,count-1 do begin
;        if modis_aod_data[lt_pos[count_i]] le 0.0 then continue
;        print,out_date,string([modis_lon_data[lt_pos[count_i]],modis_lat_data[lt_pos[count_i]],modis_aod_data[lt_pos[count_i]]])
;      endfor
      
      if (modis_aod_data[min_pos[0]] le 0.0) then continue
      print,'The three output formats of the nearest point to '+point_name[point_i]+' in file '+file_basename(file_list[file_i])+':'
      print,out_date,string([modis_lon_data[min_pos[0]],modis_lat_data[min_pos[0]],modis_aod_data[min_pos[0]]])
      print,out_date,modis_lon_data[min_pos[0]],modis_lat_data[min_pos[0]],modis_aod_data[min_pos[0]],format='(A0,",",3(F0,:,","))'
      print,out_year,out_month,out_day,modis_lon_data[min_pos[0]],modis_lat_data[min_pos[0]],modis_aod_data[min_pos[0]],format='(I0,"-",I02,"-",I02,",",3(F0.2,:,","))'
      print,'**************************************************************************************************************'
      ;若最小距离小于0.1度（约10 km），则输出结果
      if min(distance) gt 0.1 then continue
      printf,1,out_year,out_month,out_day,modis_lon_data[min_pos[0]],modis_lat_data[min_pos[0]],modis_aod_data[min_pos[0]],format='(I0,"-",I02,"-",I02," ",3(F0.3,:," "))'     
    endfor
    free_lun,1
  endfor
end