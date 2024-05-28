pro modis_swath_average
  start_time=systime(1)
  input_directory='O:/coarse_data/chapter_3/MODIS_swath/geo_out/'
  output_directory=input_directory
  file_list=file_search(input_directory,'*.tiff')
  file_n=n_elements(file_list)
  output_resolution=0.03
  output_name=output_directory+'avr.tiff'
  
  lon_min=9999.0
  lon_max=-9999.0
  lat_min=9999.0
  lat_max=-9999.0
  
  for file_i=0,file_n-1 do begin
    data=read_tiff(file_list[file_i],geotiff=geo_info)
    resolution_tag=geo_info.(0)
    geo_tag=geo_info.(1)
    data_size=size(data)
    data_col=data_size[1]
    data_line=data_size[2]  
    
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
    print,file_list[file_i]
    data=read_tiff(file_list[file_i],geotiff=geo_info)
    resolution_tag=geo_info.(0)
    geo_tag=geo_info.(1)
    data_size=size(data)
    data_col=data_size[1]
    data_line=data_size[2]
    
;    for data_col_i=0,data_col-1 do begin
;      for data_line_i=0,data_line-1 do begin
;        temp_lon=geo_tag[3]+data_col_i*resolution_tag[0]
;        temp_lat=geo_tag[4]-data_line_i*resolution_tag[1]
;        data_box_col_pos=floor((temp_lon-lon_min)/output_resolution)
;        data_box_line_pos=floor((lat_max-temp_lat)/output_resolution)
;        if data[data_col_i,data_line_i] gt 0.0 then begin
;          data_box_geo_sum[data_box_col_pos,data_box_line_pos]+=data[data_col_i,data_line_i]
;          data_box_geo_num[data_box_col_pos,data_box_line_pos]+=1.0
;        endif       
;      endfor
;    endfor

    temp_lon_array=fltarr(data_col,data_line)
    temp_lat_array=fltarr(data_col,data_line)
    for col_i=0,data_col-1 do begin
      temp_lon_array[col_i,*]=geo_tag[3]+resolution_tag[0]*col_i
    endfor
    for line_i=0,data_line-1 do begin
      temp_lat_array[*,line_i]=geo_tag[4]-resolution_tag[1]*line_i
    endfor
    data_box_col_pos=floor((temp_lon_array-lon_min)/output_resolution)
    data_box_line_pos=floor((lat_max-temp_lat_array)/output_resolution)
    data_box_geo_sum[data_box_col_pos,data_box_line_pos]+=data
    data_box_geo_num[data_box_col_pos,data_box_line_pos]+=(data gt 0.0)
    
;    col_start=floor((geo_tag[3]-lon_min)/output_resolution)
;    line_start=floor((lat_max-geo_tag[4])/output_resolution)
;    data_box_geo_sum[col_start:col_start+data_col-1,line_start:line_start+data_line-1]+=data
;    data_box_geo_num[col_start:col_start+data_col-1,line_start:line_start+data_line-1]+=(data gt 0.0)
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
  print,'Time consuming: '+strcompress(string(end_time-start_time))+' s.'
end