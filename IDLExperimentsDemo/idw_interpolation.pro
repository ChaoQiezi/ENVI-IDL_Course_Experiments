pro idw_interpolation
  input_data='O:/coarse_data/chapter_4/air_quality_data.csv'
  output_directory='O:/coarse_data/chapter_4/
  data=read_csv(input_data,header=var_name)
  var_n=n_elements(var_name)
  for var_i=2,var_n-1 do begin
    out_file=output_directory+'air_quality_'+var_name[var_i]+'_idw.tiff'
    lon_data=data.(0)
    lat_data=data.(1)
    var_data=data.(var_i)
    
    data_n=n_elements(var_data)
    lon_min=min(lon_data)
    lon_max=max(lon_data)
    lat_min=min(lat_data)
    lat_max=max(lat_data)
    resolution=0.001
    
    data_box_geo_col=ceil((lon_max-lon_min)/resolution)
    data_box_geo_line=ceil((lat_max-lat_min)/resolution)
    data_box_geo=fltarr(data_box_geo_col,data_box_geo_line)

    data_box_geo_col_pos=floor((lon_data-lon_min)/resolution)
    data_box_geo_line_pos=floor((lat_max-lat_data)/resolution)
    data_box_geo[data_box_geo_col_pos,data_box_geo_line_pos]=var_data

    data_box_geo_out=fltarr(data_box_geo_col,data_box_geo_line)
    
    for data_box_geo_col_i=0,data_box_geo_col-1 do begin
      for data_box_geo_line_i=0,data_box_geo_line-1 do begin
        if data_box_geo[data_box_geo_col_i,data_box_geo_line_i] eq 0.0 then begin
          distance_sum=0.0
          interpol_value=0.0
          lon_temp=lon_min+resolution*data_box_geo_col_i
          lat_temp=lat_max-resolution*data_box_geo_line_i      
          for data_i=0L,data_n-1 do begin
            Di=sqrt((lon_temp-lon_data[data_i])^2.0+(lat_temp-lat_data[data_i])^2.0)
            distance_sum=distance_sum+1.0/((Di)^2.0)
          endfor         
          for data_i=0L,data_n-1 do begin
            Di=sqrt((lon_temp-lon_data[data_i])^2.0+(lat_temp-lat_data[data_i])^2.0)
            interpol_value=interpol_value+1.0/((Di)^2.0)*var_data[data_i]*(1.0/distance_sum)
          endfor
          data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=interpol_value         
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

    write_tiff,out_file,data_box_geo_out,/float,geotiff=geo_info
  endfor
end