# @Author   : ChaoQiezi
# @Time     : 2023-09-12  23:20
# @Email    : chaoqiezi.one@qq.com

"""
This script is used to learn basic grammar of python.
"""

import numpy as np
from osgeo import gdal

# 第一问
def question1():
    a = np.arange(24, dtype=np.float32).reshape(6, 4)
    b = 3
    c = np.array([3])
    d = np.array([9, 3, 1])
    print(a[4, 3])  # 取第3列第4行的数值
    print(a.flatten()[15])  # 取第15个索引的数值
    print(a + b)
    print(a[1, 1] + b)  # 8.0
    print(a + c)  # 与IDL结果不一致, 这是因为c是一维数组, 会自动广播
    # print(a + d)  # 直接报错, 维度不一致


# 第二问
def question2():
    a = np.array([[3, 9, 10], [2, 7, 5], [4, 1, 6]])
    b = np.array([[7, 10, 2], [5, 8, 9], [3, 1, 6]])
    print(a + b)
    print(a * b)

# 第三问
def question3():
    a = np.array([[0, 5, 3], [4, 0, 2], [0, 7, 8]])
    b = np.array([[0, 0, 1], [9, 7, 4], [1, 0, 2]])
    # 取a大于3的结果，其余为0
    print((a > 3) * a)  # or this
    print(np.where(a > 3, a, 0))
    # 取b中小于等于4的结果，其余为9
    print((a <= 4) * a + (a > 4) * 9)
    print(np.where(a <= 4, a, 9))
    # 计算A和B的均值
    print((a + b) / 2)
    print(np.mean(a + b))  # or this
    # 计算A和B的均值, 0不纳入计算
    print((a + b) / ((a > 0) + (b > 0)))


def write_tiff(out_path: str, data: np.ndarray):
    driver = gdal.GetDriverByName('GTiff')
    out_ds = driver.Create(out_path, data.shape[1], data.shape[0], 1, gdal.GDT_Float32)  # col, row
    out_ds.GetRasterBand(1).WriteArray(data)
    out_ds.FlushCache()
    del out_ds

def question4():
    a = np.arange(1024*1024, dtype=np.float32).reshape(1024, 1024)
    write_tiff(r'D:\Objects\JuniorFallTerm\IDLProgram\Project\PyExperiments\Experiments\week1\temp.tiff', a)


if __name__ == '__main__':
    question1()
    question2()
    question3()
    question4()