# @Author   : ChaoQiezi
# @Time     : 2023-09-26  19:58
# @Email    : chaoqiezi.one@qq.com

"""
This script is used to 用于读取MODIS SWATH产品中与某点位最接近的像元的有效值
"""

import os
import glob
import numpy as np
import datetime
from pyhdf.SD import SD


def read_h4(h4_path, ds_name):
    """
    该函数用于读取HDF4文件的数据集
    :param h4_path:
    :param ds_name:
    :return:
    """

    f = SD(h4_path)
    data = f.select(ds_name)[:]
    f.end() # 关闭文件

    return data


def read_h4_attr(h4_path, ds_name, attr_name):
    """
    该函数用于读取HDF4文件数据集的属性
    :param h4_path:
    :param ds_name:
    :param attr_name:
    :return:
    """

    f = SD(h4_path)
    attr = f.select(ds_name).attributes()[attr_name]
    f.end()

    return attr


# 准备
in_dir = r'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_3\MODIS_SWATH'
out_dir = r'D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_3\OutMePy'
if not os.path.exists(out_dir):
    os.makedirs(out_dir)
aod_name = 'Image_Optical_Depth_Land_And_Ocean'
lon_name = 'Longitude'
lat_name = 'Latitude'
sf_name = 'scale_factor'
off_name = 'add_offset'
valid_range_name = 'valid_range'
point_lon = 116.40  # 北京经纬度
point_lat = 39.90
max_distance = 0.1  # 约等于11KM


# 预
h4_paths_list = glob.glob(os.path.join(in_dir, r'MYD04_3K*.hdf'))

# 循环处理
with open(os.path.join(out_dir, 'nearest_point_value.txt'), 'w') as f:
    for h4_path in h4_paths_list:
        h4_name = os.path.basename(h4_path)
        # 读取数据集和相关属性
        aod = read_h4(h4_path, aod_name).astype(np.float32)
        lon = read_h4(h4_path, lon_name)
        lat = read_h4(h4_path, lat_name)
        sf = read_h4_attr(h4_path, aod_name, sf_name)
        off = read_h4_attr(h4_path, aod_name, off_name)
        valid_range = read_h4_attr(h4_path, aod_name, valid_range_name)

        # 获取年月日(年积日==>年月日)
        year = int(h4_name[10:14])
        days = int(h4_name[14:17])
        date = datetime.datetime(year, 1, 1) + datetime.timedelta(days - 1)
        year, month, day = date.year, date.month, date.day


        # 数据集处理
        aod[(aod < valid_range[0]) | (aod > valid_range[1])] = np.nan
        aod = aod * sf + off

        # 距离
        distances = np.sqrt((lon - point_lon) ** 2 + (lat - point_lat) ** 2)
        distances[np.isnan(aod)] = np.nan  # 排除无效值
        distances[distances > max_distance] = np.nan  # 范围限制

        # 选择最接近的有效的像元
        if np.all(np.isnan(distances)):
            continue
        nearest_pixel_ix = np.nanargmin(distances)
        nearest_pixel_aod = aod.flat[nearest_pixel_ix]  # flat属性用于将数组转换为一维数组
        nearest_pixel_lon = lon.flat[nearest_pixel_ix]
        nearest_pixel_lat = lat.flat[nearest_pixel_ix]

        f.write('{:d}-{:02d}-{:02d},{:.3f},{:.3f},{:.3f}\n'.format(
            year, month, day, nearest_pixel_lon, nearest_pixel_lat, nearest_pixel_aod))
