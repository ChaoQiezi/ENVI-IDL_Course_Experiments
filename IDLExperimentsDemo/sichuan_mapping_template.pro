pro sichuan_mapping_template
  in_dir='P:/TROPOMI/Chengdu/2020/AI/geo_out/'
  out_path='P:/TROPOMI/Chengdu/2020/AI/geo_out/png_out/'
  dir_test=file_test(out_path,/directory)
  if dir_test eq 0 then begin
    file_mkdir,out_path
  endif
  shp_china='O:/coarse_data/chapter_7/china_province.shp'
  shp_city='O:/coarse_data/chapter_7/Sichuan_city_wgs84.shp'
  file_list=file_search(in_dir,'*.tiff',count=file_n)
  display_min_lat=25.0
  display_max_lat=35.0
  display_min_lon=97.0
  display_max_lon=109.0
  plot_min=0.0
  plot_max=5.0
  cb_min=0.0
  cb_max=5.0
  display_unit='Aerosol Index';'NO$_2$ ($\times$10$^-^$$^4^$ mol / m$^2$)'
  for file_i=88,file_n-1 do begin
    out_png=out_path+file_basename(file_list[file_i],'.tiff')+'.png'
    data_mapping=read_tiff(file_list[file_i],geotiff=geo_info)
    data_size=size(data_mapping)
    data_box_geo_col=data_size[1]
    data_box_geo_line=data_size[2]
    zoom_factor=ceil(1000.0/float(data_size[1]))
    resolution=geo_info.(0)
    geo_range=geo_info.(1)
    lon_min=geo_range[3]
    lon_max=geo_range[3]+(resolution[0]*data_size[1])
    lat_min=geo_range[4]-(resolution[1]*data_size[2])
    lat_max=geo_range[4]
    
    parameter_box_geo_out=rotate(data_mapping,7)
    parameter_box_geo_out=parameter_box_geo_out*parameter_box_geo_out/parameter_box_geo_out
    parameter_box_geo_out=congrid(parameter_box_geo_out,data_box_geo_col*zoom_factor,data_box_geo_line*zoom_factor)
    loadct,22,rgb_table=rgb
    im=image(parameter_box_geo_out,rgb_table=rgb,map_projection='geographic',grid_units=2,$
      image_location=[lon_min,lat_min],image_dimension=[lon_max-lon_min,lat_max-lat_min],$
      dimension=[800,800])
      
    im.MAX_VALUE=plot_max
    im.MIN_VALUE=plot_min

    im.TITLE=file_basename(file_list[file_i],'.tiff')
    im.font_name='Palatino'
    im.font_size=10
;    title_position=im.title.position
;    title_position[1]=title_position[1]-0.011
;    title_position[3]=title_position[3]-0.011
;    im.title.position=title_position

    grid=im.MAPGRID
    grid.LABEL_POSITION=0
    grid.BOX_AXES=0
    grid.BOX_THICK=0.5
    grid.HORIZON_THICK=0.5
    grid.HORIZON_COLOR='black'
    grid.LINESTYLE=3
    grid.THICK=0.5
    grid.FONT_NAME='Palatino'
    grid.FONT_SIZE=14

    map1=map('Geographic',/overplot,limit=[display_min_lat,display_min_lon,display_max_lat,display_max_lon])
    grid1=map1.MAPGRID
    grid1.FONT_NAME='Palatino'
    grid1.FONT_SIZE=14
    ;m1=mapcontinents(/countries,thick=1.0,color='black')
    m2=mapcontinents(shp_china,linestyle=2,thick=1.0,color='black')
    m3=mapcontinents(shp_city,linestyle=2,thick=1.0,color='black')
    
    ;map1.position=[0.15,0.15,0.9,0.9]
    map1_position=map1.position
    map1_position=map1.position
    image_x_start=map1_position[0]
    image_x_end=map1_position[2]
    image_x_distance=image_x_end-image_x_start
    image_y_start=map1_position[1]
    image_y_end=map1_position[3]

    im['Latitude'].LABEL_ANGLE=90
    im['Longitude'].LABEL_ANGLE=0
    mg=im.MAPGRID
    mlons=mg.LONGITUDES
    mlats=mg.LATITUDES
    for i=0,n_elements(mlons)-1 do mlons[i].LABEL_ALIGN=0
    for i=0,n_elements(mlats)-1 do mlats[i].LABEL_ALIGN=0
    mlons[n_elements(mlons)-1].LABEL_SHOW=0
    mlats[n_elements(mlats)-1].LABEL_SHOW=0
    
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
    
    s=symbol(image_x_start,image_y_start-0.055,'circle',target=im,$
      sym_size=0.5,sym_color='black',sym_thick=1.5)  
    t=text(image_x_start+0.02,image_y_start-0.06,'City center',target=im,$
      font_name='Palatino',font_size=14)
                  
    c=colorbar(target=im,orientation=0,title=display_unit)
    scalebar_x_start=image_x_start+0.15
    scalebar_x_end=image_x_end
    scalebar_y_start=image_y_start-0.065
    scalebar_y_end=image_y_start-0.035
    c.POSITION=[scalebar_x_start,scalebar_y_start,scalebar_x_end,scalebar_y_end]
    c.RANGE=[cb_min,cb_max]
    c.BORDER=1
    c.FONT_NAME='Palatino'
    c.FONT_SIZE=14
    
;    read_png,'O:/north.png',data
;    img=image(data,/current)
;    img.position=[0.85,0.75,0.9,0.85]
    
    im.save,out_png,border=0;,resolution=150
    im.close
  endfor
end