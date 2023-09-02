#!/bin/bash

# 查询终端支持的颜色数目
colors=$(tput colors)

# 打印终端支持的颜色
for ((i = 0; i < colors; i++)); do
    tput setaf $i
    echo "Color $i"
done

# 重置颜色
tput sgr0
