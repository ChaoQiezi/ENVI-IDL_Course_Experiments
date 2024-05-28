pro data_box_geo_generating,longitude,latitude,target_data,resolution,data_box_geo,data_box_geo_out,geo_info
  lon_min=min(longitude)
  lon_max=max(longitude)
  lat_min=min(latitude)
  lat_max=max(latitude)
  
  data_box_geo_col=ceil((lon_max-lon_min)/resolution)
  data_box_geo_line=ceil((lat_max-lat_min)/resolution)
  data_box_geo=fltarr(data_box_geo_col,data_box_geo_line)
  
  data_box_geo_col_pos=floor((longitude-lon_min)/resolution)
  data_box_geo_line_pos=floor((lat_max-latitude)/resolution)
  data_box_geo[data_box_geo_col_pos,data_box_geo_line_pos]=target_data

  data_box_geo_out=fltarr(data_box_geo_col,data_box_geo_line)
  for data_box_geo_col_i=1,data_box_geo_col-2 do begin
    for data_box_geo_line_i=1,data_box_geo_line-2 do begin
      if (data_box_geo[data_box_geo_col_i,data_box_geo_line_i]) eq 0.0 then begin
        temp_window=data_box_geo[data_box_geo_col_i-1:data_box_geo_col_i+1,data_box_geo_line_i-1:data_box_geo_line_i+1]
        temp_window=(temp_window gt 0.0)*temp_window
        temp_window_sum=total(temp_window)
        temp_window_num=total(temp_window gt 0.0)
        if (temp_window_num ge 3) then begin
          interpol_value=temp_window_sum/temp_window_num
          data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=interpol_value
        endif
      endif else begin
        data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=data_box_geo[data_box_geo_col_i,data_box_geo_line_i]
      endelse
    endfor
  endfor
  
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
end

pro txt_to_geotiff
  txt_file='O:/coarse_data/chapter_4/2013_year_aop.txt'
  openr,1,txt_file
  str=''
  readf,1,str 
  parameters=strsplit(str,' ',/extract)
  print,parameters
  par_n=n_elements(parameters)
  line=file_lines(txt_file)-1
  data=fltarr(par_n,line)
  readf,1,data
  free_lun,1
  
  longitude=data[0,*]
  latitude=data[1,*]
  resolution=0.18
  
  for par_i=2,par_n-1 do begin
    out_tiff='O:/coarse_data/chapter_4/2013_year_'+parameters[par_i]+'.tiff'
    target_data=data[par_i,*]    
    data_box_geo_generating,longitude,latitude,target_data,resolution,data_box_geo,data_box_geo_out,geo_info
    write_tiff,out_tiff,data_box_geo_out,geotiff=geo_info,/float
  endfor  
end