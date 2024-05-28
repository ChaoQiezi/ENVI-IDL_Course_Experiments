pro tiff_to_hdf5
  input_directory='O:/coarse_data/chapter_2/NO2/average/'
  output_directory='O:/coarse_data/chapter_2/NO2/average/hdf5/'
  dir_test=file_test(output_directory,/directory)
  if dir_test eq 0 then begin
    file_mkdir,output_directory
  endif
  hdf5_out_name=output_directory+'OMI_NO2_Month_Product.h5'
  file_list=file_search(input_directory,'month*.tiff')
  
  file_id=h5f_create(hdf5_out_name)
  att_value_temp='OMI monthly NO2 product of 2017 - 2018'
  datatype_id=h5t_idl_create(att_value_temp)
  dataspace_id=h5s_create_simple([1])
  attr_id=h5a_create(file_id,'Description',datatype_id,dataspace_id)
  h5a_write,attr_id,att_value_temp
  
  data_group_id=h5g_create(file_id,'OMI monthly data')
  
  for file_i=0,n_elements(file_list)-1 do begin
    target_data=read_tiff(file_list[file_i],geotiff=geo_info)
    data_size=size(target_data)
    data_box_col=data_size[1]
    data_box_line=data_size[2]
    resolution_tag=geo_info.(0)
    geo_tag=geo_info.(1)    
    dataset_name=file_basename(file_list[file_i],'.tiff')
    
    datatype_id=h5t_idl_create(target_data)
    dataspace_id=h5s_create_simple([data_box_col,data_box_line])
    dataset_id=h5d_create(data_group_id,dataset_name,datatype_id,dataspace_id,$
      chunk_dimensions=[data_box_col,data_box_line],gzip=9)
    h5d_write,dataset_id,target_data
    
    att_value_temp=0
    datatype_id=h5t_idl_create(att_value_temp)
    dataspace_id=h5s_create_simple([1])
    attr_id=h5a_create(dataset_id,'Fill_Value',datatype_id,dataspace_id)
    h5a_write,attr_id,att_value_temp

    att_value_temp=1
    datatype_id=h5t_idl_create(att_value_temp)
    dataspace_id=h5s_create_simple([1])
    attr_id=h5a_create(dataset_id,'Scale_Factor',datatype_id,dataspace_id)
    h5a_write,attr_id,att_value_temp   
    
    att_value_temp='mol / km2'
    datatype_id=h5t_idl_create(att_value_temp)
    dataspace_id=h5s_create_simple([1])
    attr_id=h5a_create(dataset_id,'Unit',datatype_id,dataspace_id)
    h5a_write,attr_id,att_value_temp
  endfor
  ;geo_group_id=h5g_create(data_group_id,'geo data')
  geo_group_id=h5g_create(file_id,'geo data')
  datatype_id=h5t_idl_create(resolution_tag[0:1])
  dataspace_id=h5s_create_simple([2])
  dataset_id=h5d_create(geo_group_id,'grid_space',datatype_id,dataspace_id)
  h5d_write,dataset_id,resolution_tag[0:1]
  
  datatype_id=h5t_idl_create(geo_tag[3:4])
  dataspace_id=h5s_create_simple([2])
  dataset_id=h5d_create(geo_group_id,'ul_corner',datatype_id,dataspace_id)
  h5d_write,dataset_id,geo_tag[3:4]
  
  h5a_close,attr_id
  h5t_close,datatype_id
  h5s_close,dataspace_id
  h5d_close,dataset_id
  h5g_close,gid
  h5f_close,file_id
end