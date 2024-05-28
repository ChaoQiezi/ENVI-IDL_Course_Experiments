function hdf4_data_get,file_name,sds_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,data
end

function hdf4_caldata_get,file_name,sds_name,scale_name,offset_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  att_index=hdf_sd_attrfind(sds_id,scale_name)
  hdf_sd_attrinfo,sds_id,att_index,data=scale_data
  att_index=hdf_sd_attrfind(sds_id,offset_name)
  hdf_sd_attrinfo,sds_id,att_index,data=offset_data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  data_size=size(data)
  data_cal=fltarr(data_size[1],data_size[2],data_size[3])
  for layer_i=0,data_size[3]-1 do data_cal[*,*,layer_i]=scale_data[layer_i]*(data[*,*,layer_i]-offset_data[layer_i])
  data=!null
  return,data_cal
end

pro modis_l1b_st_retrieval
  modis_file='O:/coarse_data/chapter_5/MYD021KM.A2013278.0525.006.2013278174924.hdf'
  cloud_file='O:/coarse_data/chapter_5/MYD35_L2.A2013278.0525.006.2014103014542.hdf'
  output_directory='O:/coarse_data/chapter_5/'
  result_name=output_directory+'ts.tiff'
  qkm_ref=hdf4_caldata_get(modis_file,'EV_250_Aggr1km_RefSB','reflectance_scales','reflectance_offsets')
  km_ref=hdf4_caldata_get(modis_file,'EV_1KM_RefSB','reflectance_scales','reflectance_offsets')
  km_ems=hdf4_caldata_get(modis_file,'EV_1KM_Emissive','radiance_scales','radiance_offsets')
  
  band1=qkm_ref[*,*,0]
  band2=qkm_ref[*,*,1]
  band19=km_ref[*,*,13]
  band31=km_ems[*,*,10]
  band32=km_ems[*,*,11]
  qkm_ref=!null
  km_ref=!null
  km_ems=!null
  
  a31=-64.60363
  b31=0.440817
  a32=-68.72575
  b32=0.473453
  
  c1=1.19104E8
  c2=14388.0
  lam31=11.03
  lam32=12.02
  t31=c2/(lam31*alog(1.0+c1/((lam31^5.0)*band31)))
  t32=c2/(lam32*alog(1.0+c1/((lam32^5.0)*band32)))
  
  w=((0.02-alog(band19/band2))/0.6321)^2.0
  tao31=(1.01636-0.10346*w)*(w lt 2.0)+$
    (1.11795-0.15536*w)*((w ge 2.0) and (w lt 4.0))+$
    (0.77313-0.07404*w)*(w ge 4.0)
  delta_tao31=(band31 gt 318.0)*0.08+$
    ((band31 gt 278.0) and (band31 le 318.0))*(0.00325*(band31-278.0)-0.05)+$
    (band31 le 278)*(-0.05)
  tao31=tao31+delta_tao31
  tao32=(1.02144-0.13927*w)*(w lt 2.0)+$
    (1.09361-0.17980*w)*((w ge 2.0) and (w lt 4.0))+$
    (0.65166-0.07354*w)*(w ge 4.0)
  delta_tao32=(band32 gt 318.0)*0.095+$
    ((band32 gt 278.0) and (band32 le 318.0))*(0.004*(band32-278.0)-0.065)+$
    (band32 le 278)*(-0.065)
  tao32=tao32+delta_tao32
  
  ndvi=(band2-band1)/(band2+band1)
  pv=(ndvi-0.15)/(0.9-ndvi)
  pv=(ndvi lt 0.15)*0.0+$
    (ndvi ge 0.15) and (ndvi le 0.9)*pv+$
    (ndvi gt 0.9)*1.0
  rv=0.92762+0.07033*pv
  rs=0.99782+0.08362*pv
  delta_emi=((pv eq 0.0) or (pv eq 1.0))*0.0+$
    ((pv gt 0.0) and (pv lt 0.5))*0.003796*pv+$
    ((pv gt 0.5) and (pv lt 0.5))*0.003796*(1.0-pv)+$
    (pv eq 0.5)*0.001898
  emi31=pv*rv*0.98672+(1.0-pv)*rs*0.96767+delta_emi
  emi32=pv*rv*0.98990+(1.0-pv)*rs*0.97790+delta_emi
  
  c31=emi31*tao31
  c32=emi32*tao32
  d31=(1.0-tao31)*(1.0+(1.0-emi31)*tao31)
  d32=(1.0-tao32)*(1.0+(1.0-emi32)*tao32)
  a0=(d32*(1.0-c31-d31)/(d32*c31-d31*c32))*a31-(d31*(1.0-c32-d32)/(d32*c31-d31*c32))*a32
  a1=1.0+d31/(d32*c31-d31*c32)+(d32*(1.0-c31-d31)/(d32*c31-d31*c32))*b31
  a2=d31/(d32*c31-d31*c32)+(d31*(1.0-c32-d32)/(d32*c31-d31*c32))*b32
  
  ts=a0+a1*t31-a2*t32
  
  write_tiff,result_name,ts,/float
end