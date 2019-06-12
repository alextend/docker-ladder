## 关于
根据线上各种一键脚本进行组合改装，实现低配置量搭建梯子。

__优点：__
1. 一键安装ssr和wireguard环境及账号管理系统。
2. 同时运行两套VPN方案。

__缺点：__
1. 无法同时运行两套账号管理系统。


## 运行环境
```
Ubuntu 16.04/bash
```


## 安装方法
```

curl -O https://raw.githubusercontent.com/alextend/docker-ladder/master/install.sh && chmod +x install.sh && ./install.sh
或
curl -sSL https://raw.githubusercontent.com/alextend/docker-ladder/master/install.sh | bash

```

## 维护

```powershell
# 启动wireguard管理系统
sudo /etc/init.d/wgweb-start

# 启动ssr管理系统
sudo /etc/init.d/ssrweb-start
```
>注：两套管理系统不能同时运行。

## 声明
纯研究用，勿用于非法途径。
