# @Author   : ChaoQiezi
# @Time     : 2023/10/10  14:13
# @Email    : chaoqiezi.one@qq.com

"""
This script is used to 用于对MODIS SWATH数据集进行GLT校正(重投影)
"""

from osgeo import gdal
import os
from glob import glob
from pyhdf.SD import SD


def read_h4(h4_path: str, ds_name: str):
    """
    该函数用于读取HDF4文件的数据集
    :param h4_path: HDF4文件的路径
    :param ds_name: 数据集名称
    :return: 返回数据集(数组形式)
    """

    hdf = SD(h4_path)  # 获取HDF4文件的句柄
    ds = hdf.select(ds_name)[:]  # 获取目标数据集
    hdf.end()  # 关闭HDF4文件, 释放资源

    return ds


def read_h4_attr(h4_path: str, ds_name: str, attr_name: str):
    """
    该函数用于读取HDF4文件数据集的属性
    :param h4_path: HDF4文件的路径
    :param ds_name: 数据集名称
    :param attr_name: 属性名称
    :return: 返回属性值
    """

    hdf = SD(h4_path)  # 获取HDF4文件的句柄
    attr = hdf.select(ds_name).attributes()[attr_name]  # 获取目标数据集的属性
    hdf.end()  # 关闭HDF4文件, 释放资源

    return attr


def write_tiff(tiff_path, raster_data)

# 准备工作
in_dir = r"D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_3\MODIS_SWATH"
out_dir = r"D:\Objects\JuniorFallTerm\IDLProgram\Experiments\ExperimentalData\chapter_3\py_out_week4"
target_ds_name = 'Image_Optical_Depth_Land_And_Ocean'
lon_name = 'Longitude'
lat_name = 'Latitude'
range_name = 'valid_range'
scale_factor_name = 'scale_factor'
add_offset_name = 'add_offset'
if not os.path.exists(out_dir):
    os.makedirs(out_dir)

# 检索
hdf_paths = glob(os.path.join(in_dir, '*.hdf'))

for hdf_path in hdf_paths:
    # 获取原始数据
    target_ds = read_h4(hdf_path, target_ds_name)
    lon = read_h4(hdf_path, lon_name)
    lat = read_h4(hdf_path, lat_name)
    valid_range = read_h4_attr(hdf_path, target_ds_name, range_name)
    scale_factor = read_h4_attr(hdf_path, target_ds_name, scale_factor_name)
    add_offset = read_h4_attr(hdf_path, target_ds_name, add_offset_name)

    # 输出临时文件-准备
    target_tiff_path = os.path.join(out_dir, 'target.tiff')
    lon_tiff_path = os.path.join(out_dir, 'lon.tiff')
    lat_tiff_path = os.path.join(out_dir, 'lat.tiff')


























