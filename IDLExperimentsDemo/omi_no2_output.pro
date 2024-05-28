function h5_data_get,file_name,dataset_name
  file_id=h5f_open(file_name)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro omi_no2_output
  file_name='M:/coarse_data/chapter_2/NO2/2017/OMI-Aura_L3-OMNO2d_2017m0101_v003-2018m0627t042221.he5'
  dataset_name='/HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2TropCloudScreened'
  out_directory='M:/coarse_data/chapter_2/output/'
  dir_test=file_test(out_directory,/directory)
  if dir_test eq 0 then begin
    file_mkdir,out_directory
  endif
  out_name=out_directory+file_basename(file_name,'.he5')+'.tiff'
  data_temp=h5_data_get(file_name,dataset_name)
  data_temp=((data_temp gt 0.0)*data_temp*10.0^10.0)/(!const.NA);单位转换为mol/km2
  data_temp=rotate(data_temp,7)
  
  geo_info={$
    MODELPIXELSCALETAG:[0.25,0.25,0.0],$;x、y、z方向的像元分辨率
    MODELTIEPOINTTAG:[0.0,0.0,0.0,-180.0,90.0,0.0],$;坐标转换信息，前三个0.0代表栅格图像上的第0,0,0个像元位置（z方向一般不存在），后面-180.0代表x方向第0个位置对应的经度是-180.0度，90.0代表y方向第0个位置对应的纬度是90.0度
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}
    
  write_tiff,out_name,data_temp,/float,geotiff=geo_info
end