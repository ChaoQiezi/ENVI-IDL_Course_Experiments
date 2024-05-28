# @Author   : ChaoQiezi
# @Time     : 2023-09-19  21:29
# @Email    : chaoqiezi.one@qq.com

"""
This script is used to 计算年、季、月均值
"""

import os
import glob
import numpy as np
from scipy import constants
import h5py
from osgeo import gdal

def write_tiff(out_path, data, geotrans, rows=720, cols=1440, bands=1):

    driver = gdal.GetDriverByName('GTiff')
    df = driver.Create(out_path, cols, rows, bands, gdal.GDT_Float32)
    df.SetGeoTransform(geotrans)
    df.SetProjection('WGS84')
    df.GetRasterBand(1).WriteArray(data)
    df.FlushCache()
    df = None


# 准备工作
in_dir = r'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_2'
geotrans = (-180, 0.25, 0, 90, 0, -0.25)  # 仿射变换参数: (左上角经度, 经度分辨率, 旋转角度, 左上角纬度, 旋转角度, 纬度分辨率)

# 读取数据
file_paths = glob.glob(os.path.join(in_dir, r'**\OMI-Aura_L3*.he5'), recursive=True)  # recursive=True表示递归查找,**表示任意个子目录
years = set([int(os.path.basename(file)[19:23]) for file in file_paths])  # 从文件名中提取年份
year_box = {year: [] for year in years}  # 用于存放每年的数据
season_box = {season: [] for season in ['winter', 'spring', 'summer', 'autumn']}  # 用于存放每季的数据
month_box = {month: [] for month in range(1, 13)}  # 用于存放每月的数据
season_info = {1: 'winter', 2: 'winter', 3: 'spring', 4: 'spring', 5: 'spring', 6: 'summer', 7: 'summer', 8: 'summer', 9: 'autumn', 10: 'autumn', 11: 'autumn', 12: 'winter'}

for path in file_paths:
    year = int(os.path.basename(path)[19:23])
    month = int(os.path.basename(path)[24:26])
    season = season_info[month]
    with h5py.File(path, 'r') as f:
        data = f['HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2TropCloudScreened'][:]
        # 缺失值处理
        data[data < 0] = np.nan
        # 阿伏伽德罗常数也可以使用scipy.constants中的value
        data = (data * 10 ** 10) / constants.Avogadro
        # 北极在上
        data = np.flipud(data)
        year_box[year].append(data)
        season_box[season].append(data)
        month_box[month].append(data)

# 写入文件
out_dir = r'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_2\PyOutput'
if not os.path.exists(out_dir):
    os.makedirs(out_dir)
for year, data in year_box.items():
    out_path = os.path.join(out_dir, f'OMI_NO2_{year}_mean.tif')
    write_tiff(out_path, np.nanmean(np.array(data), axis=0), geotrans)  # RuntimeWarning: Mean of empty slice是因为某一像元所有位置均为NAN
for season, data in season_box.items():
    out_path = os.path.join(out_dir, f'OMI_NO2_{season}_mean.tif')
    write_tiff(out_path, np.nanmean(np.array(data), axis=0), geotrans)
for month, data in month_box.items():
    out_path = os.path.join(out_dir, f'OMI_NO2_{month}_mean.tif')
    write_tiff(out_path, np.nanmean(np.array(data), axis=0), geotrans)
