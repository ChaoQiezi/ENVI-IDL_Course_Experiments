pro geo_box_generating,longitude,latitude,target_data,resolution,geo_box,geo_box_out,geo_info
  lon_min=min(longitude)
  lon_max=max(longitude)
  lat_min=min(latitude)
  lat_max=max(latitude)
  
  geo_box_col=ceil((lon_max-lon_min)/resolution)
  geo_box_line=ceil((lat_max-lat_min)/resolution)
  geo_box=fltarr(geo_box_col,geo_box_line)
  
  geo_box_col_pos=floor((longitude-lon_min)/resolution)
  geo_box_line_pos=floor((lat_max-latitude)/resolution)
  geo_box[geo_box_col_pos,geo_box_line_pos]=target_data
  
  geo_box_copy=fltarr(geo_box_col+2,geo_box_line+2)
  geo_box_copy[1:geo_box_col,1:geo_box_line]=geo_box
  
  geo_box_out=fltarr(geo_box_col,geo_box_line)
  for geo_box_col_i=1,geo_box_col do begin
    for geo_box_line_i=1,geo_box_line do begin
      if geo_box_copy[geo_box_col_i,geo_box_line_i] eq 0.0 then begin
        temp_window=geo_box_copy[geo_box_col_i-1:geo_box_col_i+1,geo_box_line_i-1:geo_box_line_i+1]
        temp_window=(temp_window gt 0.0)*temp_window
        temp_window_sum=total(temp_window)
        temp_window_num=total(temp_window gt 0.0)
        if (temp_window_num gt 3) then begin
          geo_box_out[geo_box_col_i-1,geo_box_line_i-1]=temp_window_sum/temp_window_num
        endif
      endif else begin
        geo_box_out[geo_box_col_i-1,geo_box_line_i-1]=geo_box_copy[geo_box_col_i,geo_box_line_i]
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

pro txt_read
  filename='O:/coarse_data/chapter_4/2013_year_aop.txt'
  openr,1,filename
  str=' '
  readf,1,str
  parameters=strsplit(str,' ',/extract)
  par_n=n_elements(parameters)
  line=file_lines(filename)-1
  data=fltarr(par_n,line)
  readf,1,data
  free_lun,1
  
  longitude=data[0,*]
  latitude=data[1,*]
  resolution=0.18
  
  for par_i=2,par_n-1 do begin
    out_tiff='O:/coarse_data/chapter_4/2013_year_'+parameters[par_i]+'.tiff'
    target_data=data[par_i,*]
    geo_box_generating,longitude,latitude,target_data,resolution,geo_box,geo_box_out,geo_info
    write_tiff,out_tiff,geo_box_out,/float,geotiff=geo_info
  endfor
end