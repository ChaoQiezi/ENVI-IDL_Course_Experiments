function hdf4_data_get,file_name,sds_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,data
end

function hdf4_caldata_get,file_name,sds_name,scale_name,offset_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  att_index=hdf_sd_attrfind(sds_id,scale_name)
  hdf_sd_attrinfo,sds_id,att_index,data=scale_data
  att_index=hdf_sd_attrfind(sds_id,offset_name)
  hdf_sd_attrinfo,sds_id,att_index,data=offset_data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  data_size=size(data)
  data_ref=fltarr(data_size[1],data_size[2],data_size[3])
  for layer_i=0,data_size[3]-1 do begin
    data_ref[*,*,layer_i]=scale_data[layer_i]*(data[*,*,layer_i]-offset_data[layer_i])
  endfor
  data=!null
  return,data_ref
end

pro modis_l1b_glt
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  modis_file='O:/coarse_data/chapter_5/MYD021KM.A2013278.0525.006.2013278174924.hdf'
  output_directory='O:/coarse_data/chapter_5/'
  result_name='O:/coarse_data/chapter_5/MYD021KM.A2013278.0525.006.2013278174924_RGB_GEO.tiff'
  qkm_ref=hdf4_caldata_get(modis_file,'EV_250_Aggr1km_RefSB','reflectance_scales','reflectance_offsets')
  hkm_ref=hdf4_caldata_get(modis_file,'EV_500_Aggr1km_RefSB','reflectance_scales','reflectance_offsets')
  ref_data_size=size(qkm_ref)
  modis_target_data=fltarr(3,ref_data_size[1],ref_data_size[2])
  modis_target_data[0,*,*]=qkm_ref[*,*,0]
  modis_target_data[1,*,*]=hkm_ref[*,*,1]
  modis_target_data[2,*,*]=hkm_ref[*,*,0]
  modis_lon_data=hdf4_data_get(modis_file,'Longitude')
  modis_lat_data=hdf4_data_get(modis_file,'Latitude')
  modis_lon_data=congrid(modis_lon_data,ref_data_size[1],ref_data_size[2],/interp)
  modis_lat_data=congrid(modis_lat_data,ref_data_size[1],ref_data_size[2],/interp)
  qkm_ref=!null
  hkm_ref=!null
  
  out_lon=output_directory+'lon_out.tiff'
  out_lat=output_directory+'lat_out.tiff'
  out_target=output_directory+'target.tiff'
  write_tiff,out_lon,modis_lon_data,/float
  write_tiff,out_lat,modis_lat_data,/float
  write_tiff,out_target,modis_target_data,/float
  
  envi_open_file,out_lon,r_fid=x_fid;打开经度数据，获取经度文件id
  envi_open_file,out_lat,r_fid=y_fid;打开纬度数据，获取纬度文件id
  envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

  out_name_glt=output_directory+file_basename(modis_file,'.hdf')+'_glt.img'
  out_name_glt_hdr=output_directory+file_basename(modis_file,'.hdf')+'_glt.hdr'
  i_proj=envi_proj_create(/geographic)
  o_proj=envi_proj_create(/geographic)
  envi_glt_doit,$
    i_proj=i_proj,x_fid=x_fid,y_fid=y_fid,x_pos=0,y_pos=0,$;指定创建GLT所需输入数据信息
    o_proj=o_proj,pixel_size=pixel_size,rotation=0.0,out_name=out_name_glt,r_fid=glt_fid;指定输出GLT文件信息

  out_name_geo=output_directory+file_basename(modis_file,'.hdf')+'_georef.img'
  out_name_geo_hdr=output_directory+file_basename(modis_file,'.hdf')+'_georef.hdr'
  envi_georef_from_glt_doit,$
    glt_fid=glt_fid,$;指定重投影所需GLT文件信息
    fid=target_fid,pos=[0,1,2],$;指定待投影数据id
    out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息

  envi_file_query,geo_fid,dims=data_dims,nb=nb,nl=nl,ns=ns
  target_data=fltarr(nb,ns,nl)
  target_data[0,*,*]=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)
  target_data[1,*,*]=envi_get_data(fid=geo_fid,pos=1,dims=data_dims)
  target_data[2,*,*]=envi_get_data(fid=geo_fid,pos=2,dims=data_dims)
  
  map_info=envi_get_map_info(fid=geo_fid)
  geo_loc=map_info.(1)
  px_size=map_info.(2)

  geo_info={$
    MODELPIXELSCALETAG:[px_size[0],px_size[1],0.0],$
    MODELTIEPOINTTAG:[0.0,0.0,0.0,geo_loc[2],geo_loc[3],0.0],$
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}

  write_tiff,result_name,target_data,/float,geotiff=geo_info

  envi_file_mng,id=x_fid,/remove
  envi_file_mng,id=y_fid,/remove
  envi_file_mng,id=target_fid,/remove
  envi_file_mng,id=glt_fid,/remove
  envi_file_mng,id=geo_fid,/remove
  file_delete,[out_lon,out_lat,out_target,out_name_glt,out_name_glt_hdr,out_name_geo,out_name_geo_hdr]
  
  envi_batch_exit,/no_confirm
end