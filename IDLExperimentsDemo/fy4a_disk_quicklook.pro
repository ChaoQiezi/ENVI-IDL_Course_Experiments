function h5_data_get,file_name,dataset_name
  file_id=h5f_open(file_name)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro fy4a_disk_quicklook
  input_directory='O:/coarse_data/chapter_4/'
  ouput_directory='O:/coarse_data/chapter_4/'
  file_list=file_search(input_directory,'*DISK*1000M*.HDF')
  for file_i=0,n_elements(file_list)-1 do begin
    out_tiff=ouput_directory+file_basename(file_list[file_i],'.HDF')+'.tiff'
    out_jpeg=ouput_directory+file_basename(file_list[file_i],'.HDF')+'.jpeg'
    band_red=h5_data_get(file_list[file_i],'NOMChannel03')
    band_green=h5_data_get(file_list[file_i],'NOMChannel02')
    band_blue=h5_data_get(file_list[file_i],'NOMChannel01')        
    
    data_size=size(band_blue)
    target_data=uintarr(3,data_size[1],data_size[2])
    target_data[0,*,*]=band_red
    target_data[1,*,*]=band_green
    target_data[2,*,*]=band_blue
    target_data=((target_data gt 0) and (target_data lt 4095))*target_data
    write_tiff,out_tiff,target_data,/short
    
    band_red=!null
    band_green=!null
    band_blue=!null
    
    data_n=n_elements(target_data[0,*,*])
    min_pos=long(0.02*data_n)
    max_pos=long(0.98*data_n)
 
    temp_data=target_data[0,*,*]
    band_red_sort=sort(temp_data)
    band_red_min_pos=band_red_sort[min_pos]
    band_red_min=temp_data[band_red_min_pos]
    band_red_max_pos=band_red_sort[max_pos]
    band_red_max=temp_data[band_red_max_pos]
    temp_data=!null
    band_red_sort=!null
    
    temp_data=target_data[1,*,*]
    band_green_sort=sort(temp_data)
    band_green_min_pos=band_green_sort[min_pos]
    band_green_min=temp_data[band_green_min_pos]
    band_green_max_pos=band_green_sort[max_pos]
    band_green_max=temp_data[band_green_max_pos]
    temp_data=!null
    band_green_sort=!null
    
    
    temp_data=target_data[2,*,*]
    band_blue_sort=sort(temp_data)
    band_blue_min_pos=band_blue_sort[min_pos]
    band_blue_min=temp_data[band_blue_min_pos]
    band_blue_max_pos=band_blue_sort[max_pos]
    band_blue_max=temp_data[band_blue_max_pos]
    temp_data=!null
    band_blue_sort=!null
    
    jpeg_data=bytarr(3,data_size[1],data_size[2])
    jpeg_data[0,*,*]=bytscl(target_data[0,*,*],min=band_red_min,max=band_red_max)
    jpeg_data[1,*,*]=bytscl(target_data[1,*,*],min=band_green_min,max=band_green_max)
    jpeg_data[2,*,*]=bytscl(target_data[2,*,*],min=band_blue_min,max=band_blue_max)
    write_jpeg,out_jpeg,jpeg_data,true=1,order=1
    
    target_data=!null
  endfor
end