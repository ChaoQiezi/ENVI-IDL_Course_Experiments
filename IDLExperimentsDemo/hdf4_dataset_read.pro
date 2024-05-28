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

pro hdf4_dataset_read
  file_name='M:/coarse_data/chapter_1/MODIS_2018_mod04_3k/MYD04_3K.A2018122.0625.061.2018124152903.hdf'
  result_name='M:/coarse_data/chapter_1/MODIS_2018_mod04_3k/MYD04_3K.A2018122.0625.061.2018124152903.tiff'
  
  modis_lon_data=hdf4_data_get(file_name,'Longitude')
  modis_lat_data=hdf4_data_get(file_name,'Latitude')
  modis_target_data=hdf4_data_get(file_name,'Image_Optical_Depth_Land_And_Ocean')
  
;  modis_sd_id=hdf_sd_start(file_name,/read) ;打开文件，获取文件ID
;  modis_sds='Longitude' ;指定数据集名称
;  modis_sds_index=hdf_sd_nametoindex(modis_sd_id,modis_sds) ;把数据集名称转换为数据集索引号
;  modis_sds_id=hdf_sd_select(modis_sd_id,modis_sds_index) ;选中目标数据集ID
;  hdf_sd_getdata,modis_sds_id,modis_lon_data ;读取目标数据集内容
;  
;  modis_sds='Latitude'
;  modis_sds_index=hdf_sd_nametoindex(modis_sd_id,modis_sds)
;  modis_sds_id=hdf_sd_select(modis_sd_id,modis_sds_index)
;  hdf_sd_getdata,modis_sds_id,modis_lat_data
;  
;  modis_sds='Image_Optical_Depth_Land_And_Ocean'
;  modis_sds_index=hdf_sd_nametoindex(modis_sd_id,modis_sds)
;  modis_sds_id=hdf_sd_select(modis_sd_id,modis_sds_index)
;  hdf_sd_getdata,modis_sds_id,modis_target_data
  
  sf=hdf4_attdata_get(file_name,'Image_Optical_Depth_Land_And_Ocean','scale_factor')
  fv=hdf4_attdata_get(file_name,'Image_Optical_Depth_Land_And_Ocean','_FillValue')
  print,sf
;  modis_att_index=hdf_sd_attrfind(modis_sds_id,'scale_factor')
;  hdf_sd_attrinfo,modis_sds_id,modis_att_index,data=sf
;  modis_att_index=hdf_sd_attrfind(modis_sds_id,'_FillValue')
;  hdf_sd_attrinfo,modis_sds_id,modis_att_index,data=fv
  
;  hdf_sd_endaccess,modis_sds_id
;  hdf_sd_end,modis_sd_id
  
  modis_target_data=(modis_target_data ne fv[0])*modis_target_data*sf[0]
  write_tiff,result_name,modis_target_data,/float
end