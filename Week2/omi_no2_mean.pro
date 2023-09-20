function extract_start_end, files_path, files_amount=files_amount
    ; 该函数用于从存储多个路径数组中获取年份信息并返回起始-终止年份
    years = list()
    for i = 0, files_amount - 1 do begin
        year = fix(strmid(file_basename(files_path[i]), 19, 4))
        if where(years eq year) EQ -1 then years.add, year
    endfor
    years = years.toarray()
    
    return, [min(years), max(years)]
end

function read_h5, h5_path, group_path=group_path, ds_name=ds_name
    ; 该函数用于读取HDF5文件的数据集
    
    ; 如果关键字参数没有传入, 设置默认
    if ~keyword_set(group_path) then group_path = 'HDFEOS/GRIDS/ColumnAmountNO2/Data Fields'
    if ~keyword_set(ds_name) then ds_name = 'ColumnAmountNO2TropCloudScreened'
    
    file_id = h5f_open(h5_path)  ; 默认可读模式打开, 返回文件ID(指针)
    group_id = h5g_open(file_id, group_path)  ; 获取组ID
    
    ds_id = h5d_open(group_id, ds_name)
    ds = h5d_read(ds_id)  ; 获取数据集
    
    ; 关闭以释放资源
    h5d_close, ds_id
    h5g_close, group_id
    h5f_close, file_id
    
    return, ds
end


pro OMI_NO2_mean
    ; 此程序用于计算OMI-NO2产品下ColumnAmountNO2TropCloudScreened数据集的$
    ; 月均值、 季均值、 年均值, 并以Geotiff形式输出, 输出单位为mol/km2
    start_time = systime(1)  ; 记录时间

    ; 准备
    in_dir = 'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_2'
    out_dir = 'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_2\Output'
    if ~file_test(out_dir, /directory) then file_mkdir, out_dir  ; 是否存在该文件夹, 不存在创建
    ; 基本信息
    ds_dir = 'HDFEOS/GRIDS/ColumnAmountNO2/Data Fields'
    ds_name = 'ColumnAmountNO2TropCloudScreened'
    rows = 720
    cols = 1440
    season_info = hash(3, 'spring', 4, 'spring', 5, 'spring',$
        6, 'summer', 7, 'summer', 8, 'summer', 9, 'autumn', 10, 'autumn',$
        11, 'autumn', 12, 'winter', 1, 'winter', 2, 'winter')
    ; 创建哈希表进行月份与季节(key)的对应
    
    ; 获取起始-终止年份
    files_path = file_search(in_dir, 'OMI-Aura_L3*.he5', count=files_amount)  ; 查询所有满足条件的文件路径
    start_end_year = extract_start_end(files_path, files_amount=files_amount)
    years_amount = start_end_year[-1] - start_end_year[0] + 1  ; 获取年份数目
    
    ; 创建存储池
    year_box = hash()  ; 哈希表, 类似python-字典
    month_box = hash()
    season_box = hash()
    for i = start_end_year[0], start_end_year[-1] do year_box[i] = list()  ; list类似python-列表
    for i = 1, 12 do month_box[i] = list()
    foreach i, ['spring', 'summer', 'autumn', 'winter'] do season_box[i] = list()
    
    ; 循环每一个HDF5文件
    for file_i = 0, files_amount - 1 do begin
        ; 获取当前循环的HDF5文件路径及基本信息
        df_path = files_path[file_i]
        df_year = fix(strmid(file_basename(df_path), 19, 4))
        df_month = fix(strmid(file_basename(df_path), 24, 2))
        df_season = season_info[df_month]
        
        ; 读取对流层NO2的垂直柱含量及基本处理
        ds = read_h5(df_path)
        ds[where(ds lt 0, /null)] = !values.F_NAN
        ; 单位换算molec/cm^2 ==> mol/km^2, 1mol = 6.022 * 10 ^ 23(即NA), 1km^2 = 10 ^ 10 cm^2
        ds = (ds * 10.0 ^ 10) / !const.NA  ; !const.NA = 6.022 * 10 ^ 23
        ; 上方为北极(由于此极轨卫星从南极拍摄, 故影像第一行为南极位置的第一行, 需南北颠倒)
        ds = rotate(ds, 7)  ; 7: x ==> x, y ==> -y
        ; 如果自己写不用函数或可
        ; ds = ds[*, rows - indgen(rows, start=1)]
        ; 加和
        year_box[df_year].add, ds
        month_box[df_month].add, ds
        season_box[df_season].add, ds
    endfor
    
    ; 投影信息
    geo_info={$
        MODELPIXELSCALETAG:[0.25,0.25,0.0],$  ; 经度分辨率, 维度分辨率, 高程分辨率(Z轴) ==> 不知前面是否反了
        MODELTIEPOINTTAG:[0.0,0.0,0.0,-180.0,90.0,0.0],$  ; 第0列第0行第0高的像元点的经纬度高程分别为 -180, 90, 0
        GTMODELTYPEGEOKEY:2,$  ; 设置为地理坐标系
        GTRASTERTYPEGEOKEY:1,$  ; 像素的表示类型, 北上图像(North-Up)
        GEOGRAPHICTYPEGEOKEY:4326,$  ; 地理坐标系为WGS84
        GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
        GEOGANGULARUNITSGEOKEY:9102,$  ; 单位为度
        GEOGSEMIMAJORAXISGEOKEY:6378137.0,$  ; 主半轴长度为6378137.0m
        GEOGINVFLATTENINGGEOKEY:298.25722}  ; 反扁平率为298.25722
    
    ; 计算均值(求取均值警告存在Floating illegal operand是由于某一像元位置任意时间上均为NAN导致, 不影响输出结果)
    for i = start_end_year[0], start_end_year[-1] do begin
        year_box[i] = mean(year_box[i].toarray(), dimensio=1, /nan)  ; dimension=1表示第一个维度(索引从1开始)
        year_path = out_dir + '\year_mean_' + strcompress(string(i), /remove_all) + '.tiff' 
        write_tiff, year_path, year_box[i], geotiff=geo_info, /float
    endfor
    for i = 1, 12 do begin
        month_box[i] = mean(month_box[i].toarray(), dimension=1, /nan)
        month_path = out_dir + '\month_mean_' + strcompress(string(i), /remove_all) + '.tiff'
        write_tiff, month_path, month_box[i], geotiff=geo_info, /float
    endfor
    foreach i, ['spring', 'summer', 'autumn', 'winter'] do begin
        season_box[i] = mean(season_box[i].toarray(), dimension=1, /nan)
        season_path = out_dir + '\season_mean_' + i + '.tiff'
        write_tiff, season_path, season_box[i], geotiff=geo_info, /float
    endforeach
    end_time  = systime(1)
    print, end_time - start_time, format="均值处理完成, 用时: %6.2f s"
end