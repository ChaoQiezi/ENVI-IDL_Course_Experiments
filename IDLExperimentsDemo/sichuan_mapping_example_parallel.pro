pro sichuan_mapping_example,input_directory,prefixion,output_directory,output_resolution
  shp_china='O:/coarse_data/chapter_6/shp_file/china_province.shp'
  shp_city='O:/coarse_data/chapter_6/shp_file/Sichuan_city_wgs84.shp'
  file_name=file_search(input_directory,'*'+prefixion+'*.tiff',count=draw_n)
  plot_min=0.0
  plot_max=0.001
  cb_min=0.0
  cb_max=1.0
  cb_title='NO$_2$ ($\times$10$^{-3}$ mol / m$^2$)'

  display_lat_min=25.0
  display_lat_max=35.0
  display_lon_min=97.0
  display_lon_max=109.0
  image_x_start=0.05
  image_x_end=0.95
  image_y_start=0.15
  image_y_end=0.95
  if draw_n eq 1 then begin
    data_mapping=read_tiff(file_name[0],geotiff=geo_info)
    out_name=output_directory+prefixion+'.png'
  endif
  if draw_n ge 2 then begin
    lon_min=9999.0
    lon_max=-9999.0
    lat_min=9999.0
    lat_max=-9999.0
    out_name=output_directory+prefixion+'.png'
    for draw_i=0,draw_n-1 do begin     
      data=read_tiff(file_name[draw_i],geotiff=geo_info)
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
    for draw_i=0,draw_n-1 do begin
      data=read_tiff(file_name[draw_i],geotiff=geo_info)
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
    data_mapping=data_box_geo_sum/data_box_geo_num

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
  endif
   
  
  ;data_mapping=data_mapping*data_mapping/data_mapping
  im=image(data_mapping,/order,/buffer,geotiff=geo_info,rgb_table=22,min_value=plot_min,max_value=plot_max,$
    limit=[display_lat_min,display_lon_min,display_lat_max,display_lon_max],$
    dimension=[1000,1000],position=[image_x_start,image_y_start,image_x_end,image_y_end])
  m1=mapcontinents(shp_china,linestyle=2,color='black')
  m2=mapcontinents(shp_city,linestyle=2,thick=2,color='black')

  true_position=im.position
  image_x_start=true_position[0]
  image_x_end=true_position[2]
  image_y_start=true_position[1]
  image_y_end=true_position[3]

  title_date='('+strmid(file_basename(file_name[0]),26,2)+'/'+$
    strmid(file_basename(file_name[0]),24,2)+'/'+$
    strmid(file_basename(file_name[0]),20,4)+')'
  im.title='TROPOMI NO$_2$ result over Sichuan area '+title_date
  im.title.font_name='Palatino'
  im.title.font_size=20
  im.title.font_style=1

  im.mapgrid.label_position=0
  im.mapgrid.font_name='Palatino'
  im.mapgrid.font_size=16
  im.mapgrid.font_style=1
  im.mapgrid.linestyle=3
  im.mapgrid.horizon_thick=3

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

  t=text(103.3d,30.46d,'Chengdu',/data,$
    font_name='Palatino',font_size=12)
  t=text(101.8d,31.8d,'Aba',/data,$
    font_name='Palatino',font_size=12)
  t=text(100.1d,31.5d,'Ganzi',/data,$
    font_name='Palatino',font_size=12)
  t=text(101.6d,27.65d,'Liangshan',/data,$
    font_name='Palatino',font_size=12)
  t=text(101.1d,26.7d,'Panzhihua',/data,$
    font_name='Palatino',font_size=12)
  t=text(102.5d,29.8d,'Yaan',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.0d,30.93d,'Deyang',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.1d,31.6d,'Mianyang',/data,$
    font_name='Palatino',font_size=12)
  t=text(105.2d,28.65d,'Luzhou',/data,$
    font_name='Palatino',font_size=12)
  t=text(103.4d,29.8d,'Meishan',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.75d,30.05d,'Ziyang',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.5d,29.7d,'Neijiang',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.3d,29.15d,'Zigong',/data,$
    font_name='Palatino',font_size=12)
  t=text(104.4d,28.5d,'Yibin',/data,$
    font_name='Palatino',font_size=12)
  t=text(105.0d,30.6d,'Suining',/data,$
    font_name='Palatino',font_size=12)
  t=text(105.7d,30.88d,'Nanchong',/data,$
    font_name='Palatino',font_size=12)
  t=text(107.2d,31.3d,'Dazhou',/data,$
    font_name='Palatino',font_size=12)
  t=text(106.1d,30.25d,'Guangan',/data,$
    font_name='Palatino',font_size=12)
  t=text(106.5d,31.95d,'Bazhong',/data,$
    font_name='Palatino',font_size=12)
  t=text(105.3d,32.2d,'Guangyuan',/data,$
    font_name='Palatino',font_size=12)
  t=text(103.4d,29.3d,'Leshan',/data,$
    font_name='Palatino',font_size=12)

  s=symbol(104.06d,30.67d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(101.72d,31.93d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(99.96d,31.64d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(102.27d,27.90d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(101.72d,26.58d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(103.00d,29.98d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(104.38d,31.13d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(104.73d,31.47d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(105.43d,28.87d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(103.83d,30.05d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(104.65d,30.12d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(105.05d,29.58d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(104.78d,29.35d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(104.62d,28.77d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(105.57d,30.52d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(106.08d,30.78d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(107.50d,31.22d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(106.63d,30.47d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(106.77d,31.85d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(105.83d,32.43d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)
  s=symbol(103.77d,29.57d,'circle',/data,$
    sym_size=0.5,sym_color='black',sym_thick=1.5)

  s=symbol(image_x_start+0.2,image_y_start-0.14,'circle',target=im,$
    sym_size=0.6,sym_color='black',sym_thick=1.5)
  t=text(image_x_start+0.21,image_y_start-0.145,'City center',target=im,$
    font_name='Palatino',font_size=18)

  c=colorbar(target=im)
  c.font_name='Palatino'
  c.font_size=16
  c.range=[cb_min,cb_max]
  c.title=cb_title
  cb_x_start=image_x_start+0.5
  cb_x_end=image_x_end
  cb_y_start=image_y_start-0.10
  cb_y_end=image_y_start-0.05
  c.position=[cb_x_start,cb_y_start,cb_x_end,cb_y_end]

  read_png,'O:/coarse_data/chapter_6/north.png',north_data
  north_im=image(north_data,/current)
  north_im.position=[image_x_start,image_y_start-0.15,image_x_start+0.05,image_y_start-0.05]

  sc=colorbar(rgb_table=[255,255,255])
  sc_x_start=image_x_start+0.1
  sc_x_end=image_x_start+0.4
  sc_y_start=image_y_start-0.10
  sc_y_end=image_y_start-0.05
  sc.position=[sc_x_start,sc_y_start,sc_x_end,sc_y_end]
  sc.font_name='Palatino'
  sc.font_size=16

  image_x_distance=image_x_end-image_x_start
  sc_x_distance=sc_x_end-sc_x_start
  relative_distance=sc_x_distance/image_x_distance
  end_distance=relative_distance*(display_lon_max-display_lon_min)*110.0
  sc_interval=end_distance/5
  sc.range=[0.0,end_distance]
  sc.tickinterval=sc_interval
  sc.subticklen=0
  t=text(image_x_start+0.42,image_y_start-0.10,'km',target=im,$
    font_name='Palatino',font_size=18)

  im.save,out_name
  im.close
end

pro sichuan_mapping_example_parallel
  start_time=systime(1)
  num_threads=16
  day_avr=0
  output_resolution=0.05
  input_directory='O:/coarse_data/chapter_7/TROPOMI_NO2/'
  file_list=file_search(input_directory,'*.tiff',count=file_n)
  if file_n eq 0 then return
  output_directory='O:/coarse_data/chapter_7/TROPOMI_NO2/geo_out/'
  dir_test=file_test(output_directory,/directory)
  if dir_test eq 0 then file_mkdir,output_directory
  prefixion=[' ']
  for file_i=0,file_n-1 do begin
    if day_avr eq 1 then begin
      basename_temp=strmid(file_basename(file_list[file_i]),13,15)
    endif else begin
      basename_temp=strmid(file_basename(file_list[file_i]),13,22)
    endelse    
    if total(basename_temp eq prefixion) eq 0 then begin
      prefixion=[prefixion,basename_temp]
    endif
  endfor

  prefixion_n=n_elements(prefixion)
  threads=min([num_threads,prefixion_n-1])
  p=objarr(threads)
  compile_command='.compile -v O:/Pivotal_Backup/IDL/coarse_code/sichuan_mapping_example_parallel.pro'
  prefixion_i=1
  for threads_i=0,threads-1 do begin
    p[threads_i]=obj_new('IDL_IDLBridge',output=output_directory+'output_'+string(threads_i,format='(I02)')+'.txt')
    p[threads_i]->execute,compile_command
    p[threads_i]->setvar,'input_directory',input_directory
    p[threads_i]->setvar,'prefixion',prefixion[prefixion_i]
    p[threads_i]->setvar,'output_directory',output_directory
    p[threads_i]->setvar,'output_resolution',output_resolution
    p[threads_i]->execute,'sichuan_mapping_example,input_directory,prefixion,output_directory,output_resolution',/nowait
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
        p[threads_i_free]->setvar,'output_directory',output_directory
        p[threads_i_free]->setvar,'output_resolution',output_resolution
        p[threads_i_free]->execute,'sichuan_mapping_example,input_directory,prefixion,output_directory,output_resolution',/nowait
        print,prefixion[prefixion_i]
        prefixion_i+=1
      endfor
    endif
  endwhile

  for i=0,threads-1 do obj_destroy,p[i]
  end_time=systime(1)
  print,'Time consuming is: '+string(end_time-start_time,format='(F0.2)')+' s.'
end