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

pro modis_swath_reprojection,file_name,output_directory,resolution
  result_name=output_directory+file_basename(file_name,'.hdf')+'_geo.tiff'
  ;result_name=output_directory+strmid(file_basename(file_name),10,4)+'.'+$
    ;strmid(file_basename(file_name),14,3)+'.'+$
    ;strmid(file_basename(file_name),18,2)+'.'+$
    ;strmid(file_basename(file_name),20,2)+'.geo.tiff'
  ;result_test=file_test(result_name)
  ;if result_test eq 1 then return
  if ~hdf_ishdf(file_name) then return
  if file_test(result_name) then return
  modis_lon_data=hdf4_data_get(file_name,'Longitude')
  modis_lat_data=hdf4_data_get(file_name,'Latitude')
  modis_target_data=hdf4_data_get(file_name,'LST');'Optical_Depth_Land_And_Ocean'
  scale_factor=hdf4_attdata_get(file_name,'LST','scale_factor')
  fill_value=hdf4_attdata_get(file_name,'LST','_FillValue')

  modis_target_data=(modis_target_data ne fill_value[0])*modis_target_data*scale_factor[0]
 
  data_size=size(modis_target_data)
  data_col=data_size[1]
  data_line=data_size[2]
  congrid_scale=10
  modis_lon_data=congrid(modis_lon_data,data_col,data_line,/interp)
  modis_lat_data=congrid(modis_lat_data,data_col,data_line,/interp)
  modis_lon_data_interp=congrid(modis_lon_data,data_col*congrid_scale,data_line*congrid_scale,/interp)
  modis_lat_data_interp=congrid(modis_lat_data,data_col*congrid_scale,data_line*congrid_scale,/interp)

  lon_min=min(modis_lon_data)
  lon_max=max(modis_lon_data)
  lat_min=min(modis_lat_data)
  lat_max=max(modis_lat_data)

  data_box_geo_col=fix((lon_max-lon_min)/resolution)+1
  data_box_geo_line=fix((lat_max-lat_min)/resolution)+1
  data_box_lon=fltarr(data_box_geo_col,data_box_geo_line)
  data_box_lat=fltarr(data_box_geo_col,data_box_geo_line)
  data_box_geo=fltarr(data_box_geo_col,data_box_geo_line)
  data_box_lon[*,*]=-999.0
  data_box_lat[*,*]=-999.0

  data_box_lon_col_pos=floor((modis_lon_data_interp-lon_min)/resolution)
  data_box_lon_line_pos=floor((lat_max-modis_lat_data_interp)/resolution)
  data_box_lon[data_box_lon_col_pos,data_box_lon_line_pos]=modis_lon_data_interp

  data_box_lat_col_pos=floor((modis_lon_data_interp-lon_min)/resolution)
  data_box_lat_line_pos=floor((lat_max-modis_lat_data_interp)/resolution)
  data_box_lat[data_box_lon_col_pos,data_box_lon_line_pos]=modis_lat_data_interp

  data_box_geo_col_pos=floor((modis_lon_data-lon_min)/resolution)
  data_box_geo_line_pos=floor((lat_max-modis_lat_data)/resolution)
  data_box_geo[data_box_geo_col_pos,data_box_geo_line_pos]=(modis_target_data gt 0.0)*modis_target_data+(modis_target_data le 0.0)*(-9999.0)

  data_box_geo_out=fltarr(data_box_geo_col,data_box_geo_line)
  window_size=9
  jump_size=(window_size-1)/2
  for data_box_geo_line_i=jump_size,data_box_geo_line-jump_size-1 do begin
    for data_box_geo_col_i=jump_size,data_box_geo_col-jump_size-1 do begin
      if data_box_geo[data_box_geo_col_i,data_box_geo_line_i] eq 0.0 then begin
        distance=sqrt((data_box_lon[data_box_geo_col_i,data_box_geo_line_i]-data_box_lon[(data_box_geo_col_i-jump_size):(data_box_geo_col_i+jump_size),(data_box_geo_line_i-jump_size):(data_box_geo_line_i+jump_size)])^2+$
          (data_box_lat[data_box_geo_col_i,data_box_geo_line_i]-data_box_lat[(data_box_geo_col_i-jump_size):(data_box_geo_col_i+jump_size),(data_box_geo_line_i-jump_size):(data_box_geo_line_i+jump_size)])^2)
        distance_sort_pos=sort(distance)
        data_box_geo_window=data_box_geo[(data_box_geo_col_i-jump_size):(data_box_geo_col_i+jump_size),(data_box_geo_line_i-jump_size):(data_box_geo_line_i+jump_size)]
        data_box_geo_sort=data_box_geo_window[distance_sort_pos]
        fill_pos=where(data_box_geo_sort ne 0.0)
        fill_value=data_box_geo_sort[fill_pos[0]]
        data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=fill_value
      endif else begin
        data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=data_box_geo[data_box_geo_col_i,data_box_geo_line_i]
      endelse
    endfor
  endfor

  data_box_geo_out=abs((data_box_geo_out gt 0.0)*data_box_geo_out)*(data_box_lat ne -999.0)

  geo_info={$
    MODELPIXELSCALETAG:[resolution,resolution,0.0],$
    MODELTIEPOINTTAG:[0.0,0.0,0.0,lon_min,lat_max,0.0],$
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}

  print,result_name
  write_tiff,result_name,data_box_geo_out,/float,geotiff=geo_info
  jump1:
end

pro modis_swath_reprojection_parallel
  num_threads=16
  time1=systime(1)
  print,systime()

  input_directory='R:/modis/modis_lst/'
  output_directory='R:/modis/modis_lst/geo_out/'
  resolution=0.01
  directory_exist=file_test(output_directory,/directory)
  if (directory_exist eq 0) then begin
    file_mkdir,output_directory
  endif
  file_list=file_search(input_directory,'*.hdf')

  file_n=n_elements(file_list)
  prefixion=['']
  basename_compare=''
  for file_i=0,file_n-1 do begin
    basename_temp=file_list[file_i]
    if (basename_temp ne basename_compare) then begin
      prefixion=[prefixion,basename_temp]
      basename_compare=basename_temp
    endif
  endfor

  prefixion_n=n_elements(prefixion)

  if (prefixion_n ge 2) then begin
    num_threads=num_threads
    threads=min([num_threads,prefixion_n-1])
    p=objarr(threads)
    time_record=dblarr(2,prefixion_n-1)
    file_threads=strarr(threads)
    Function_position=routine_filepath('modis_swath_reprojection_parallel')
    prefixion_i=1
    for threads_i=0,threads-1 do begin
      file_threads[threads_i]=prefixion[prefixion_i]
      file_name=prefixion[prefixion_i]
      p[threads_i]=obj_new('IDL_IDLBridge',output=output_directory+'output_glt'+strcompress(string(prefixion_i),/remove_all)+'.txt')
      p[threads_i]->Execute,".compile "+"'"+Function_position+"'"
      p[threads_i]->Setvar,'file_name',file_name
      p[threads_i]->Setvar,'output_directory',output_directory
      p[threads_i]->Setvar,'resolution',resolution
      p[threads_i]->Execute,$
        'modis_swath_reprojection,file_name,output_directory,resolution',/nowait
      print,systime()+' Starting the glt processing of '+prefixion[prefixion_i]
      time_record[0,prefixion_i-1]=systime(1)
      if (prefixion_i le prefixion_n-1) then begin
        prefixion_i=prefixion_i+1
      endif
    endfor
    signal=intarr(threads)
    print,'Successfully initialized and waiting for signal.'

    while (1 gt 0) do begin
      for i=0,threads-1 do begin
        signal(i)=p(i)->Status()
      endfor
      if (total(signal) eq 0) then begin
        time_record_pos=where(time_record[1,*] eq 0.0)
        time_record[1,time_record_pos]=systime(1)
        break
      endif
      child=where(signal eq 0,child_count)
      if (child_count ne 0) then begin
        for i=0,child_count-1 do begin
          thread_idle=child[i]
          file_pos=where(prefixion eq file_threads[thread_idle])
          if (time_record[1,file_pos-1] eq 0.0) then begin
            time_record[1,file_pos-1]=systime(1)
            print,systime()+' The glt processing of '+file_threads[thread_idle]+' is end.'
          endif
          if (prefixion_i le prefixion_n-1) then begin
            file_threads[thread_idle]=prefixion[prefixion_i]
            file_name=prefixion[prefixion_i]
            p[thread_idle]->Setvar,'file_name',file_name
            p[thread_idle]->Setvar,'output_directory',output_directory
            p[thread_idle]->Setvar,'resolution',resolution
            p[thread_idle]->Execute,$
              'modis_swath_reprojection,file_name,output_directory,resolution',/nowait
            print,systime()+' Starting the glt processing of '+prefixion[prefixion_i]
            time_record[0,prefixion_i-1]=systime(1)
            prefixion_i=prefixion_i+1
          endif
        endfor
      endif
    endwhile
    time2=systime(1)
    print,'Processing is end, the totol time consuming is:'+strcompress(string(time2-time1))+' s.'
    print,prefixion[1:prefixion_n-1]+string(time_record[1,*]-time_record[0,*])+' s.',format='(1a)'
    for i=0,threads-1 do begin
      obj_destroy,p(i)
    endfor
  endif
end