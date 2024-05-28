function h5_data_get,file_name,dataset_name
  file_id=h5f_open(file_name)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro fy4a_glt
  start_time=systime(1)
;风四地理查找表文件下载地址：http://satellite.nsmc.org.cn/PortalSite/StaticContent/DocumentDownload.aspx?TypeID=3
  georaw_file='P:/FY4A/FullMask_Grid_1000.raw'
  openr,1,georaw_file
  georaw_data=dblarr(2,10992,10992)
  readu,1,georaw_data
  free_lun,1
  lon_data=georaw_data[1,*,*]
  lat_data=georaw_data[0,*,*]
  write_tiff,'P:/FY4A/FullMask_Grid_1000_lon.tiff',lon_data,/double
  write_tiff,'P:/FY4A/FullMask_Grid_1000_lat.tiff',lat_data,/double
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  fy4a_file='P:/FY4A/FY4A-_AGRI--_N_DISK_1047E_L1-_FDI-_MULT_NOM_20200330080000_20200330081459_1000M_V0001.HDF'
  output_directory='P:/FY4A/'
  result_name='P:/FY4A/FY4A_20200330080000_band1_geo.tiff'
  target_data=h5_data_get(fy4a_file,'NOMChannel01')
  fy4a_lon_data=read_tiff('P:/FY4A/FullMask_Grid_1000_lon.tiff')
  fy4a_lat_data=read_tiff('P:/FY4A/FullMask_Grid_1000_lat.tiff')
  fy4a_target_data=target_data*0.00025-0.0125
  
  pos=where((fy4a_lon_data ge 102.0) and (fy4a_lon_data le 105.0) and (fy4a_lat_data ge 29.0) and (fy4a_lat_data le 31.0),count)
  if count eq 0 then return
  data_size=size(fy4a_target_data)
  data_col=data_size[1]
  pos_col=pos mod data_col
  pos_line=pos/data_col
  col_min=min(pos_col)
  col_max=max(pos_col)
  line_min=min(pos_line)
  line_max=max(pos_line)

  out_lon=output_directory+'lon_out.tiff'
  out_lat=output_directory+'lat_out.tiff'
  out_target=output_directory+'target.tiff'
  write_tiff,out_lon,fy4a_lon_data[col_min:col_max,line_min:line_max],/float
  write_tiff,out_lat,fy4a_lat_data[col_min:col_max,line_min:line_max],/float
  write_tiff,out_target,fy4a_target_data[col_min:col_max,line_min:line_max],/float

  envi_open_file,out_lon,r_fid=x_fid;打开经度数据，获取经度文件id
  envi_open_file,out_lat,r_fid=y_fid;打开纬度数据，获取纬度文件id
  envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

  out_name_glt=output_directory+file_basename(fy4a_file,'.hdf')+'_glt.img'
  out_name_glt_hdr=output_directory+file_basename(fy4a_file,'.hdf')+'_glt.hdr'
  i_proj=envi_proj_create(/geographic)
  o_proj=envi_proj_create(/geographic)
  envi_glt_doit,$
    i_proj=i_proj,x_fid=x_fid,y_fid=y_fid,x_pos=0,y_pos=0,$;指定创建GLT所需输入数据信息
    o_proj=o_proj,pixel_size=pixel_size,rotation=0.0,out_name=out_name_glt,r_fid=glt_fid;指定输出GLT文件信息

  out_name_geo=output_directory+file_basename(fy4a_file,'.hdf')+'_georef.img'
  out_name_geo_hdr=output_directory+file_basename(fy4a_file,'.hdf')+'_georef.hdr'
  envi_georef_from_glt_doit,$
    glt_fid=glt_fid,$;指定重投影所需GLT文件信息
    fid=target_fid,pos=0,$;指定待投影数据id
    out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息

  envi_file_query,geo_fid,dims=data_dims
  target_data=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)

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

  end_time=systime(1)
  print,end_time-start_time
  envi_batch_exit,/no_confirm
end