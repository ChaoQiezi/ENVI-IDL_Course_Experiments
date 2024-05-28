function MapGrid_Labels, orientation, location, fractional, defaultlabel
  if (location eq 0) then $
    return, orientation ? 'Equator' : 'Prime Meridian'
  degree = '!M' + string(176b) ; Use the Math symbol
  label = string(abs(location),format='(F0.2)') + degree
  suffix = orientation ? ((location lt 0) ? 'S' : 'N') : $
    ((location lt 0) ? 'W' : 'E')
  return, label + suffix
end

function strech_range_get,temp_data,min_value,max_value,strech_percent
  strech_range=fltarr(2)
  temp_his=histogram(temp_data,min=min_value,max=max_value)
  temp_pct=total(temp_his,/cumulative)*100.0/total(temp_his)
  temp_pct_floor=floor(temp_pct)
  min_pos=where(temp_pct_floor ge strech_percent)
  max_pos=where(temp_pct_floor ge (100-strech_percent))
  strech_range[0]=min_pos[0]
  strech_range[1]=max_pos[0]
  return,strech_range
end

pro sichuan_mapping_utm_rgb_example
  input_directory='O:/coarse_data/chapter_6/'
  out_directory='O:/coarse_data/chapter_6/png_out/'
  shp_china='O:/coarse_data/chapter_6/shp_file/china_province.shp'
  shp_city='O:/coarse_data/chapter_6/shp_file/Sichuan_city_wgs84.shp'
  dir_test=file_test(out_directory,/directory)
  if dir_test eq 0 then begin
    file_mkdir,out_directory
  endif
  file_list=file_search(input_directory,'LC08*_T1.tif',count=file_n)
  if file_n eq 0 then return

  display_lat_min=30.0
  display_lat_max=31.0
  display_lon_min=103.75
  display_lon_max=104.75
  image_x_start=0.1
  image_x_end=0.9
  image_y_start=0.15
  image_y_end=0.95

  for file_i=0,file_n-1 do begin
    data_mapping=read_tiff(file_list[file_i],geotiff=geo_info)    
    
    strech_range_red=strech_range_get(data_mapping[0,*,*],1,max(data_mapping[0,*,*]),2)
    strech_range_green=strech_range_get(data_mapping[1,*,*],1,max(data_mapping[1,*,*]),2)
    strech_range_blue=strech_range_get(data_mapping[2,*,*],1,max(data_mapping[2,*,*]),2)
        
    data_mapping=transpose(data_mapping,[1,2,0])
    out_png=out_directory+file_basename(file_list[file_i],'.tiff')+'.png'
    data_size=size(data_mapping)

    resolution=geo_info.(0)
    geo_loc=geo_info.(1)
    x_min=geo_loc[3]
    x_max=geo_loc[3]+data_size[1]*resolution[0]
    y_max=geo_loc[4]
    y_min=geo_loc[4]-data_size[2]*resolution[1]
    map_zone=geo_info.PROJECTEDCSTYPEGEOKEY
    if map_zone lt 32700 then begin
      utm_zone=map_zone-32600
      ns_mark=0
    endif
    if map_zone gt 32700 then begin
      utm_zone=map_zone-32700
      ns_mark=-1
    endif
    
    data_mapping_geo=make_array(data_size[1],data_size[2],3,type=data_size[4])
    input_parameter=map_proj_init('utm',/gctp,zone=utm_zone,center_latitude=ns_mark)
    output_parameter=map_proj_init('geographic',/gctp)
    for band_i=0,2 do begin
      data_mapping_geo[*,*,band_i]=map_proj_image(data_mapping[*,*,band_i],[x_min,y_min,x_max,y_max],$
        image_structure=input_parameter,map_structure=output_parameter,$
        uvrange=geo_range)
      data_mapping_geo[*,*,band_i]=(data_mapping_geo[*,*,band_i] gt 0)*data_mapping_geo[*,*,band_i]+$
        (data_mapping_geo[*,*,band_i] eq 0)*max(data_mapping_geo[*,*,band_i])
    endfor       
    print,geo_range
;    im=image(data_mapping,/order,geotiff=geo_info,$
;      min_value=[strech_range_red[0],strech_range_green[0],strech_range_blue[0]],$
;      max_value=[strech_range_red[1],strech_range_green[1],strech_range_blue[1]],$
;      dimension=[1000,1000],position=[image_x_start,image_y_start,image_x_end,image_y_end],label_format='MapGrid_Labels')
    
    im=image(data_mapping_geo,/order,$
      min_value=[strech_range_red[0],strech_range_green[0],strech_range_blue[0]],$
      max_value=[strech_range_red[1],strech_range_green[1],strech_range_blue[1]],$
      map_projection='geographic',grid_units=2,$
      image_location=[geo_range[0],geo_range[1]],image_dimension=[geo_range[2]-geo_range[0],geo_range[3]-geo_range[1]],$
      dimension=[1000,1000],position=[image_x_start,image_y_start,image_x_end,image_y_end],label_format='MapGrid_Labels')
        
    m1=mapcontinents(shp_china,linestyle=2,color='red')
    m2=mapcontinents(shp_city,linestyle=2,color='red',thick=2)
    im.limit=[display_lat_min,display_lon_min,display_lat_max,display_lon_max]
        
    true_position=im.position
    image_x_start=true_position[0]
    image_x_end=true_position[2]
    image_y_start=true_position[1]
    image_y_end=true_position[3]
    
    title_date='('+strmid(file_basename(file_list[file_i]),23,2)+'/'$
      +strmid(file_basename(file_list[file_i]),21,2)+'/'$
      +strmid(file_basename(file_list[file_i]),17,4)+')'
    im.title='Landsat TM true color image over Chengdu plain '+title_date
    im.title.font_name='Palatino'
    im.title.font_size=16
    im.title.font_style=1

    im.mapgrid.label_position=0
    im.mapgrid.BOX_AXES=1
    im.mapgrid.BOX_THICK=4
    im.mapgrid.clip=1
    im.mapgrid.color='black'
    im.mapgrid.label_color='black'
    im.mapgrid.font_name='Palatino'
    im.mapgrid.font_size=16   
    im.mapgrid.font_style=1
    im.mapgrid.linestyle=3
    im.mapgrid.thick=0.5
    im.mapgrid.horizon_thick=3
    im.mapgrid.horizon_linestyle=2
    
    lons=im.mapgrid.longitudes
    lats=im.mapgrid.latitudes
    for lons_i=0,n_elements(lons)-1 do begin
      lons[lons_i].label_angle=0
      lons[lons_i].label_align=0
    endfor
    for lats_i=0,n_elements(lats)-1 do begin
      lats[lats_i].label_angle=90
      lats[lats_i].label_align=0
    endfor
    lons[n_elements(lons)-1].label_show=0
    lats[n_elements(lats)-1].label_show=0

    read_png,'O:/coarse_data/chapter_6/north.png',north_data
    north_im=image(north_data,/current)
    north_im.position=[image_x_start,image_y_start-0.15,image_x_start+0.05,image_y_start-0.05]

    sc=colorbar(rgb_table=[255,255,255])
    sc_x_start=image_x_start+0.10
    sc_x_end=image_x_start+0.40
    sc_y_start=image_y_start-0.10
    sc_y_end=image_y_start-0.05
    sc.position=[sc_x_start,sc_y_start,sc_x_end,sc_y_end]
    sc.font_name='Palatino'
    sc.font_size=16
    image_x_distance=image_x_end-image_x_start
    sc_x_distance=sc_x_end-sc_x_start
    relative_distance=sc_x_distance/image_x_distance
    true_distance=relative_distance*(display_lon_max-display_lon_min)*110.0
    sc_interval=floor(true_distance/5)
    true_distance=sc_interval*5
    sc.range=[0.0,true_distance]
    sc.tickinterval=sc_interval
    sc.subticklen=0
    t=text(image_x_start+0.41,image_y_start-0.102,' km',target=im,font_name='Palatino',font_size=16)

    im.save,out_png
    im.close
  endfor
end