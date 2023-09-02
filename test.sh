#!/bin/bash
url="https://golang.google.cn/dl/"
web_content=$(curl -s "$url")
versions=$(echo "$web_content" | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | awk '!seen[$0]++' | head -n 40) 
echo "可安装的Go版本列表："
PS3="请选择1-40: "
select opt in ${versions[@]}; do
  echo $REPLY
  if [[ $REPLY =~ ^[0-9]+$ ]] && [[ $REPLY -gt 0 && $REPLY -lt 41 ]]; then
    echo "选择了${opt}"
    break
  else
    echo "输入了无效的数字"
  fi
done
