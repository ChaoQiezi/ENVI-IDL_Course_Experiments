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

pro modis_swath_glt
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  input_directory='O:/coarse_data/chapter_3/MODIS_swath/
  output_directory='O:/coarse_data/chapter_3/MODIS_swath/geo_out/'
  directory_exist=file_test(output_directory,/directory)
  if (directory_exist eq 0) then begin
    file_mkdir,output_directory
  endif

  file_list=file_search(input_directory,'*.hdf')
  file_n=n_elements(file_list)

  for file_i=0,file_n-1 do begin
    start_time=systime(1)
    modis_lon_data=hdf4_data_get(file_list[file_i],'Longitude')
    modis_lat_data=hdf4_data_get(file_list[file_i],'Latitude')
    modis_target_data=hdf4_data_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean')
    scale_factor=hdf4_attdata_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean','scale_factor')
    fill_value=hdf4_attdata_get(file_list[file_i],'Image_Optical_Depth_Land_And_Ocean','_FillValue')

    modis_target_data=(modis_target_data ne fill_value[0])*modis_target_data*scale_factor[0]

    out_lon=output_directory+'lon_out.tiff'
    out_lat=output_directory+'lat_out.tiff'
    out_target=output_directory+'target.tiff'
    write_tiff,out_lon,modis_lon_data,/float
    write_tiff,out_lat,modis_lat_data,/float
    write_tiff,out_target,modis_target_data,/float

    envi_open_file,out_lon,r_fid=x_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=y_fid;打开纬度数据，获取纬度文件id
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

    out_name_glt=output_directory+file_basename(file_list[file_i],'.hdf')+'_glt.img'
    out_name_glt_hdr=output_directory+file_basename(file_list[file_i],'.hdf')+'_glt.hdr'
    i_proj=envi_proj_create(/geographic)
    o_proj=envi_proj_create(/geographic)
    envi_glt_doit,$
      i_proj=i_proj,x_fid=x_fid,y_fid=y_fid,x_pos=0,y_pos=0,$;指定创建GLT所需输入数据信息
      o_proj=o_proj,pixel_size=0.03,rotation=0.0,out_name=out_name_glt,r_fid=glt_fid;指定输出GLT文件信息

    out_name_geo=output_directory+file_basename(file_list[file_i],'.hdf')+'_georef.img'
    out_name_geo_hdr=output_directory+file_basename(file_list[file_i],'.hdf')+'_georef.hdr'
    envi_georef_from_glt_doit,$
      glt_fid=glt_fid,pos=0,$;指定重投影所需GLT文件信息
      fid=target_fid,$;指定待投影数据id
      out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息

    envi_file_mng,id=x_fid,/remove
    envi_file_mng,id=y_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove
    file_delete,[out_lon,out_lat,out_target,out_name_glt,out_name_glt_hdr]

    end_time=systime(1)
    print,end_time-start_time
  endfor
  envi_batch_exit,/no_confirm
end