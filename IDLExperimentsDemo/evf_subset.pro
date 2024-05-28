pro  evf_subset
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  file_name='O:/coarse_data/chapter_4/2013_year_FMF550.tiff'
  evf_file='O:/sichuan_wgs_.evf'
  subset_name='O:/coarse_data/chapter_4/2013_year_FMF550_subset.img'
  subset_name_hdr='O:/coarse_data/chapter_4/2013_year_FMF550_subset.hdr'
  result_name='O:/coarse_data/chapter_4/2013_year_FMF550_subset.tiff'
  
  envi_open_file,file_name,r_fid=geo_fid   
  envi_file_query,geo_fid,ns=ns,nl=nl
  evf_id=envi_evf_open(evf_file)
  envi_evf_info,evf_id,num_recs=num_recs
  roi_ids=lonarr(num_recs)
  for rec_i=0,num_recs-1 do begin
    record=envi_evf_read_record(evf_id,rec_i)
    envi_convert_file_coordinates,geo_fid,xmap,ymap,record[0,*],record[1,*]
    roi_id=envi_create_roi(ns=ns,nl=nl)
    envi_define_roi,roi_id,/polygon,xpts=reform(xMap),ypts=reform(yMap)
    roi_ids[rec_i]=roi_id
    if rec_i eq 0 THEN BEGIN
      xmin=ROUND(MIN(xMap,max=xMax))
      yMin=ROUND(MIN(yMap,max=yMax))
    endif else begin
      xmin=xMin<ROUND(MIN(xMap))
      xMax=xMax>ROUND(MAX(xMap))
      yMin=yMin<ROUND(MIN(yMap))
      yMax=yMax>ROUND(MAX(yMap))
    endelse
  endfor
  xMin=xMin>0
  xmax=xMax<ns-1
  yMin=yMin>0
  ymax=yMax<nl-1
  envi_mask_doit,$
    AND_OR=1,$
    /IN_MEMORY,$
    ROI_IDS=roi_ids,$
    ns=ns,nl=nl,$
    /inside,$
    r_fid=m_fid
  out_dims=[-1,xMin,xMax,yMin,yMax]
  envi_mask_apply_doit,fid=geo_fid,pos=0,dims=out_dims,$
    m_FID=m_fid,m_pos=0,value=0,$
    out_name=subset_name,r_fid=subset_fid
  
  envi_file_query,subset_fid,dims=data_dims
  target_data=envi_get_data(fid=subset_fid,pos=0,dims=data_dims)

  map_info=envi_get_map_info(fid=subset_fid)
  geo_loc=map_info.(1)
  px_size=map_info.(2)

  geo_info={$
    MODELPIXELSCALETAG:[px_size[0],px_size[1],0.0],$
    MODELTIEPOINTTAG:[0.0,0.0,0.0,geo_loc[2],geo_loc[3],0.0],$
    GTMODELTYPEGEOKEY:2,$
    GTRASTERTYPEGEOKEY:1,$
    GEOGRAPHICTYPEGEOKEY:4326,$
    GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
    GEOGANGULARUNITSGEOKEY:9102,$
    GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
    GEOGINVFLATTENINGGEOKEY:298.25722}
  write_tiff,result_name,target_data,/float,geotiff=geo_info
  
  envi_file_mng,id=subset_fid,/remove
  file_delete,[subset_name,subset_name_hdr]
  envi_batch_exit
end