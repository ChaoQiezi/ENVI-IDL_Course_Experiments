from osgeo import gdal
from pyhdf.SD import SD
import os

"""
该程序用于对MODIS SWATH产品进行GLT校正(重投影)
"""

def swath_glt_warp(target_filename, lon_filename, lat_filename, vrt_filename, out_filename, out_geo_range, x_res_out,
                   y_res_out):
    """
    该程序基于经纬度数据集对目标数据集进行glt校正
    :param target_filename: 目标数据集的名称
    :param lon_filename: 经度数据集的名称
    :param lat_filename: 纬度数据集的名称
    :param vrt_filename:
    :param out_filename:
    :param out_geo_range:
    :param x_res_out:
    :param y_res_out:
    :return:
    """
    target_ds = gdal.Open(target_filename)
    gdal.Translate(vrt_filename, target_ds, format='vrt')  # 这是
    lines = []
    with open(vrt_filename, 'r') as f:
        for line in f:
            lines.append(line)
    lines.insert(1, '<Metadata domain="GEOLOCATION">\n')
    lines.insert(2,
                 '     <MDI key="SRS">GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9108"]],AXIS["Lat",NORTH],AXIS["Long",EAST],AUTHORITY["EPSG","4326"]]</MDI>\n')
    lines.insert(3, '     <MDI key="X_DATASET">' + lon_filename + '</MDI>\n')
    lines.insert(4, '     <MDI key="X_BAND">1</MDI>\n')
    lines.insert(5, '     <MDI key="PIXEL_OFFSET">0</MDI>\n')
    lines.insert(6, '     <MDI key="PIXEL_STEP">1</MDI>\n')
    lines.insert(7, '     <MDI key="Y_DATASET">' + lat_filename + '</MDI>\n')
    lines.insert(8, '     <MDI key="Y_BAND">1</MDI>\n')
    lines.insert(9, '     <MDI key="LINE_OFFSET">0</MDI>\n')
    lines.insert(10, '     <MDI key="LINE_STEP">1</MDI>\n')
    lines.insert(11, '  </Metadata>\n')
    with open(vrt_filename, 'w') as f:
        for line in lines:
            f.writelines(line)
    gdal.Warp(out_filename, vrt_filename, multithread=True, outputBounds=out_geo_range,
              format='GTiff', geoloc=True, dstSRS="EPSG:4326",
              xRes=x_res_out, yRes=y_res_out, dstNodata=0.0, outputType=gdal.GDT_Float32)


def main():
    # 准备工作
    file_prefix = '.hdf'
    input_directory = 'O:/coarse_data/chapter_1/MODIS_2018_mod04_3k/'
    output_directory = 'O:/coarse_data/chapter_1/MODIS_2018_mod04_3k/geo_out/'
    if not os.path.exists(output_directory):  # 检查文件夹是否存在
        os.mkdir(output_directory)

    file_list = os.listdir(input_directory)
    for file_i in file_list:
        if file_i.endswith(file_prefix):
            file_name = input_directory + file_i
            out_file = output_directory + os.path.splitext(file_i)[0] + '_geo.tiff'
            file_datasets = SD(file_name)
            lon_id = file_datasets.select('Longitude')
            lon_data = lon_id.get()
            lat_id = file_datasets.select('Latitude')
            lat_data = lat_id.get()
            aod_id = file_datasets.select('Image_Optical_Depth_Land_And_Ocean')
            aod_data = aod_id.get()
            aod_att = aod_id.attributes()
            aod_data = (aod_data > 0) * aod_data
            aod_data_conversion = aod_data * aod_att['scale_factor']
            aod_shape = aod_data_conversion.shape
            lon_name = output_directory + 'lon.tiff'
            lat_name = output_directory + 'lat.tiff'
            target_name = output_directory + 'target.tiff'
            vrt_name = output_directory + 'vrt.vrt'

            driver = gdal.GetDriverByName('GTiff')
            lon_file = driver.Create(lon_name, aod_shape[1], aod_shape[0], 1, gdal.GDT_Float32)
            band = lon_file.GetRasterBand(1)
            band.WriteArray(lon_data)
            band = None
            lon_file = None
            lat_file = driver.Create(lat_name, aod_shape[1], aod_shape[0], 1, gdal.GDT_Float32)
            band = lat_file.GetRasterBand(1)
            band.WriteArray(lat_data)
            band = None
            lat_file = None
            target_file = driver.Create(target_name, aod_shape[1], aod_shape[0], 1, gdal.GDT_Float32)
            band = target_file.GetRasterBand(1)
            band.WriteArray(aod_data_conversion)
            band = None
            target_file = None

            geo_range = None  # [90.0, 55.0, 120.0, 25.0]
            x_res = 0.03
            y_res = 0.03
            swath_glt_warp(target_name, lon_name, lat_name, vrt_name, out_file, geo_range, x_res, y_res)
            print('The georeference of ' + file_i + ' is complete.')
            # swath_georeference(file_name, file_name, dataset_name, out_file, geo_range, x_res, y_res)
            os.remove(target_name)
            os.remove(lon_name)
            os.remove(lat_name)
            os.remove(vrt_name)


if __name__ == '__main__':
    main()
