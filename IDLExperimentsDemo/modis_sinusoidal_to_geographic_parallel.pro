pro modis_sinusoidal_to_geographic,input_directory,prefixion,dataset_name,geo_resolution,output_directory
  file_name=file_search(input_directory,'*'+prefixion+'*.hdf')
  result_name=output_directory+file_basename(file_name[0],'.hdf')+'_geo.tiff'
  print,result_name
  
  sd_id=hdf_sd_start(file_name[0],/read)
  gindex=hdf_sd_attrfind(sd_id,'StructMetadata.0')
  hdf_sd_attrinfo,sd_id,gindex,data=metadata

  ul_start_pos=strpos(metadata,'UpperLeftPointMtrs')
  ul_end_pos=strpos(metadata,'LowerRightMtrs')
  ul_info=strmid(metadata,ul_start_pos,ul_end_pos-ul_start_pos)
  ul_info_spl=strsplit(ul_info,'=(,)',/extract)
  ul_prj_x=double(ul_info_spl[1])
  ul_prj_y=double(ul_info_spl[2])

  lr_start_pos=strpos(metadata,'LowerRightMtrs')
  lr_end_pos=strpos(metadata,'Projection')
  lr_info=strmid(metadata,lr_start_pos,lr_end_pos-lr_start_pos)
  lr_info_spl=strsplit(lr_info,'=(,)',/extract)
  lr_prj_x=double(lr_info_spl[1])
  lr_prj_y=double(lr_info_spl[2])

  sds_index=hdf_sd_nametoindex(sd_id,dataset_name)
  sds_id=hdf_sd_select(sd_id, sds_index)
  hdf_sd_getdata,sds_id,data
  index=hdf_sd_attrfind(sds_id,'scale_factor')
  hdf_sd_attrinfo,sds_id,index,DATA=cali_scale
  data=data*cali_scale[0]
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id

  data_size=size(data)
  sin_resolution=(lr_prj_x-ul_prj_x)/(data_size[1])
  proj_x=dblarr(data_size[1],data_size[2])
  proj_y=dblarr(data_size[1],data_size[2])
  for col_i=0,data_size[1]-1 do begin
    proj_x[col_i,*]=ul_prj_x+(sin_resolution*col_i)
  endfor
  for line_i=0,data_size[2]-1 do begin
    proj_y[*,line_i]=ul_prj_y-(sin_resolution*line_i)
  endfor

  sin_prj=map_proj_init('sinusoidal',/gctp,sphere_radius=6371007.181,center_longitude=0.0,false_easting=0.0,false_northing=0.0)
  geo_loc=map_proj_inverse(proj_x,proj_y,map_structure=sin_prj)
  geo_x=geo_loc[0,*]
  geo_y=geo_loc[1,*]

  lon_min=min(geo_x)
  lon_max=max(geo_x)
  lat_min=min(geo_y)
  lat_max=max(geo_y)
  data_box_geo_col=ceil((lon_max-lon_min)/geo_resolution)
  data_box_geo_line=ceil((lat_max-lat_min)/geo_resolution)
  data_box_geo=fltarr(data_box_geo_col,data_box_geo_line)
  data_box_geo[*,*]=-9999.0

  data_box_geo_col_pos=floor((geo_x-lon_min)/geo_resolution)
  data_box_geo_line_pos=floor((lat_max-geo_y)/geo_resolution)
  data_box_geo[data_box_geo_col_pos,data_box_geo_line_pos]=data

  data_box_geo_out=fltarr(data_box_geo_col,data_box_geo_line)
  for data_box_geo_col_i=1,data_box_geo_col-2 do begin
    for data_box_geo_line_i=1,data_box_geo_line-2 do begin
      if data_box_geo[data_box_geo_col_i,data_box_geo_line_i] eq -9999.0 then begin
        temp_window=data_box_geo[data_box_geo_col_i-1:data_box_geo_col_i+1,data_box_geo_line_i-1:data_box_geo_line_i+1]
        temp_window=(temp_window gt 0.0)*temp_window
        temp_window_sum=total(temp_window)
        temp_window_num=total(temp_window gt 0.0)
        if (temp_window_num gt 3) then begin
          data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=temp_window_sum/temp_window_num
        endif
      endif else begin
        data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=data_box_geo[data_box_geo_col_i,data_box_geo_line_i]
      endelse
    endfor
  endfor

  geo_info={$
    MODELPIXELSCALETAG:[geo_resolution,geo_resolution,0.0],$
    MODELTIEPOINTTAG:[0.0,0.0,0.0,lon_min,lat_max,0.0],$
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}

  write_tiff,result_name,data_box_geo_out,/float,geotiff=geo_info
end

pro modis_sinusoidal_to_geographic_parallel
  start_time=systime(1)
  num_threads=16
  input_directory='O:/coarse_data/chapter_3/modis_grid/'
  file_list=file_search(input_directory,'*.hdf',count=file_n)
  if file_n eq 0 then return
  output_directory='O:/coarse_data/chapter_3/modis_grid/geo_out/'
  dir_test=file_test(output_directory,/directory)
  if dir_test eq 0 then file_mkdir,output_directory
  dataset_name='LST_Day_1km'
  geo_resolution=0.01
  
  prefixion=[' ']
  for file_i=0,file_n-1 do begin
    prefixion_temp=strmid(file_basename(file_list[file_i]),8,15)
    if total(prefixion_temp eq prefixion) eq 0 then begin
      prefixion=[prefixion,prefixion_temp]
    endif    
  endfor
  
  prefixion_n=n_elements(prefixion)
  threads=min([num_threads,prefixion_n-1])
  p=objarr(threads)
  prefixion_i=1
  complie_command='.compile -v O:/Pivotal_Backup/IDL/coarse_code/modis_sinusoidal_to_geographic_parallel.pro'
  for threads_i=0,threads-1 do begin
    p[threads_i]=obj_new('IDL_IDLBridge',output=output_directory+'ouput_'+string(threads_i,format='(I02)')+'.txt')
    p[threads_i]->execute,complie_command
    p[threads_i]->setvar,'input_directory',input_directory
    p[threads_i]->setvar,'prefixion',prefixion[prefixion_i]
    p[threads_i]->setvar,'dataset_name',dataset_name
    p[threads_i]->setvar,'geo_resolution',geo_resolution
    p[threads_i]->setvar,'output_directory',output_directory
    p[threads_i]->execute,'modis_sinusoidal_to_geographic,input_directory,prefixion,dataset_name,geo_resolution,output_directory',/nowait
    print,prefixion[prefixion_i]
    prefixion_i+=1
  endfor
  signal=intarr(threads)
  
  while 1 gt 0 do begin
    for signal_i=0,threads-1 do signal[signal_i]=p[signal_i]->status()
    if (total(signal) eq 0) then break
    child=where(signal eq 0,child_count)
    if child_count gt 0 then begin
      for child_i=0,child_count-1 do begin
        threads_i_free=child[child_i]
        if prefixion_i eq prefixion_n then break
        p[threads_i_free]->setvar,'input_directory',input_directory
        p[threads_i_free]->setvar,'prefixion',prefixion[prefixion_i]
        p[threads_i_free]->setvar,'dataset_name',dataset_name
        p[threads_i_free]->setvar,'geo_resolution',geo_resolution
        p[threads_i_free]->setvar,'output_directory',output_directory
        p[threads_i_free]->execute,'modis_sinusoidal_to_geographic,input_directory,prefixion,dataset_name,geo_resolution,output_directory',/nowait
        print,prefixion[prefixion_i]
        prefixion_i+=1
      endfor
    endif
  endwhile
  
  for i=0,threads-1 do obj_destroy,p[i]
  end_time=systime(1)
  print,'Time consuming is: '+string(end_time-start_time,format='(F0.2)')+' s.'
end