# @Author   : ChaoQiezi
# @Time     : 2023-10-03  15:20
# @Email    : chaoqiezi.one@qq.com

"""
This script is used to ...
"""

import numpy as np
from scipy.interpolate import Rbf
import matplotlib.pyplot as plt

# 创建一些数据点
x = np.linspace(0, 10, 9)
y = np.sin(x)
xi = np.linspace(0, 10, 1000)

# 使用Rbf进行插值
rbf = Rbf(x, y, function='cubic') # 你可以选择不同的基函数，例如：'multiquadric', 'inverse', 'gaussian', 'linear', 'cubic', 'quintic', 'thin_plate'
yi = rbf(xi)

# 绘图展示
plt.plot(x, y, 'bo', label='Original data points')
plt.plot(xi, yi, 'r', label='Interpolated data points using Rbf')
plt.legend()
plt.show()
