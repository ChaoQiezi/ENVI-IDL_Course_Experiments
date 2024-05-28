pro modis_swath_mosaic
  input_directory='O:/coarse_data/chapter_3/MODIS_swath/geo_out/'
  output_directory='O:/coarse_data/chapter_3/MODIS_swath/mosaic/'
  directory_exist=file_test(output_directory,/directory)
  if (directory_exist eq 0) then begin
    file_mkdir,output_directory
  endif
  file_all=file_search(input_directory,'*.tiff')
  file_doy=strmid(file_basename(file_all),10,7)
  doy_uniq=file_doy[uniq(file_doy)]
  doy_n=n_elements(doy_uniq)
  output_resolution=0.03
  for doy_i=0,doy_n-1 do begin
    start_time=systime(1)
    file_list=file_search(input_directory,'*A'+doy_uniq[doy_i]+'*.tiff')
    file_n=n_elements(file_list)
    
    date=fix(strmid(doy_uniq[doy_i],4,3))
    out_year=fix(strmid(doy_uniq[doy_i],0,4))
    date_julian=imsl_datetodays(31,12,out_year-1) 
    imsl_daystodate,date_julian+date,day,month,year
    out_date=string(year,format='(I04)')+string(month,format='(I02)')+string(day,format='(I02)')
    output_name=output_directory+out_date+'_mosaic.tiff'
    if file_n eq 1 then begin
      print,'Only one file for '+doy_uniq[doy_i]+', no need to mosaic, copy the original file directly.'
      file_copy,file_list[0],output_name,/overwrite
      continue
    endif
         
    lon_min=9999.0
    lon_max=-9999.0
    lat_min=9999.0
    lat_max=-9999.0

    for file_i=0,file_n-1 do begin
      data=read_tiff(file_list[file_i],geotiff=geo_info)
      data_size=size(data)
      data_col=data_size[1]
      data_line=data_size[2]
      resolution_tag=geo_info.(0)
      geo_tag=geo_info.(1)
      temp_lon_min=geo_tag[3]
      temp_lon_max=temp_lon_min+data_col*resolution_tag[0]
      temp_lat_max=geo_tag[4]
      temp_lat_min=temp_lat_max-data_line*resolution_tag[1]
      if temp_lon_min lt lon_min then lon_min=temp_lon_min
      if temp_lon_max gt lon_max then lon_max=temp_lon_max
      if temp_lat_min lt lat_min then lat_min=temp_lat_min
      if temp_lat_max gt lat_max then lat_max=temp_lat_max
    endfor

    data_box_geo_col=ceil((lon_max-lon_min)/output_resolution)
    data_box_geo_line=ceil((lat_max-lat_min)/output_resolution)
    data_box_geo_sum=fltarr(data_box_geo_col,data_box_geo_line)
    data_box_geo_num=fltarr(data_box_geo_col,data_box_geo_line)
    for file_i=0,file_n-1 do begin
      data=read_tiff(file_list[file_i],geotiff=geo_info)
      data_size=size(data)
      data_col=data_size[1]
      data_line=data_size[2]
      resolution_tag=geo_info.(0)
      geo_tag=geo_info.(1)
      
      temp_lon=dblarr(data_col,data_line)
      temp_lat=dblarr(data_col,data_line)
      for col_i=0,data_col-1 do begin
        temp_lon[col_i,*]=geo_tag[3]+(resolution_tag[0]*col_i)
      endfor
      for line_i=0,data_line-1 do begin
        temp_lat[*,line_i]=geo_tag[4]-(resolution_tag[1]*line_i)
      endfor
      data_box_geo_col_pos=floor((temp_lon-lon_min)/output_resolution)
      data_box_geo_line_pos=floor((lat_max-temp_lat)/output_resolution)
      data_box_geo_sum[data_box_geo_col_pos,data_box_geo_line_pos]+=data
      data_box_geo_num[data_box_geo_col_pos,data_box_geo_line_pos]+=(data gt 0.0)   
    endfor
    data_box_geo_num=(data_box_geo_num gt 0.0)*data_box_geo_num+(data_box_geo_num eq 0.0)
    data_box_geo_avr=data_box_geo_sum/data_box_geo_num

    geo_info={$
      MODELPIXELSCALETAG:[output_resolution,output_resolution,0.0],$
      MODELTIEPOINTTAG:[0.0,0.0,0.0,lon_min,lat_max,0.0],$
      GTMODELTYPEGEOKEY:2,$
      GTRASTERTYPEGEOKEY:1,$
      GEOGRAPHICTYPEGEOKEY:4326,$
      GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
      GEOGANGULARUNITSGEOKEY:9102,$
      GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
      GEOGINVFLATTENINGGEOKEY:298.25722}

    write_tiff,output_name,data_box_geo_avr,geotiff=geo_info,/float
    end_time=systime(1)
    print,'Mosaic time consuming for '+doy_uniq[doy_i]+' ('+strcompress(string(file_n),/remove_all)+' files): '+strcompress(string(end_time-start_time))+' s.'
  endfor
end