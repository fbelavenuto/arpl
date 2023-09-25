# 自动化 Redpill 安装程序

这个特别的项目是为了方便我进行与Redpill相关的测试而创建的，我决定与其他用户共享。

原作者是巴西人，英语不太好，中文Readme版本基于原文润色翻译。

我尽可能让这个系统尽可能地人性化，以简化操作。安装程序会自动检测正在使用的设备是SATA接口还是USB，并准确地识别其VID和PID。为了允许内核在不设置与网络接口相关的变量的情况下启动，redpill-lkm已被修改。因此，你在使用这个安装程序时不需要再担心这个问题。感谢Jun的代码，用于生成zImage和Ramdisk补丁，已经集成在其中。如果“zImage”或“rd.gz”有任何小的更新，安装程序会重新应用这些补丁。最重要的内核模块已内置于DSM ramdisk镜像中，以实现自动外设检测。

# 重要注意事项

 - 一些用户曾经遇到过启动时间过长的问题。在这种情况下，强烈建议使用SSD作为去启动盘，如果选择通过外接设备启动，请使用一个高速的USB闪存驱动器。

 - 必须拥有至少4GB的RAM，无论是在裸机还是虚拟机中。

 - DSM内核与SATA端口兼容，不支持SAS/SCSI等。对于Device-tree模式，只有SATA端口可以工作。对于其他模式，可能支持其他类型的磁盘。

 - HBA卡可以使用，但显示SMART和序列号仅在DS3615xs、DS3617xs和DS3622xs+型号上有效。

# 使用方法

## 通用指导

要使用这个项目，下载最新可用的镜像文件，并将其烧录到USB闪存盘或SATA硬盘模块上。设置PC从烧录的媒体启动，并按照屏幕上的信息操作。

如果最后一个分区的大小超过2GiB，加载器会自动增加其大小并用这个空间作为缓存。

## 启动安装程序

### 通过终端

直接在计算机上调用"menu.sh"命令。

### 通过网页

从同一网络中的另一台机器，通过浏览器输入屏幕上显示的地址`http://<ip>:7681`。

### 通过ssh

在同一网络中的另一台机器上，使用SSH客户端，用户名： `root` 和密码： `Redp1lL-1s-4weSomE`

## 使用安装程序

安装时菜单系统是动态展示的，我希望它直观到用户可以毫无问题地使用。

无需配置VID/PID（如果使用USB闪存盘）或定义网络接口的MAC地址。如果用户想修改任何接口的MAC地址，可以在"cmdline"菜单中使用"Change MAC"选项。

如果选择了一个使用Device-tree系统来定义硬盘的型号，则无需进行任何配置。对于没有使用Device-tree的型号，需要手动完成配置，在"cmdline"菜单中有一个选项可以显示SATA控制器、DUMMY端口和正在使用的端口，以协助创建"SataPortMap"、"DiskIdxMap"和"sata_remap"（如果需要）。

另一个重要的点是，安装程序会检测CPU是否支持MOVBE指令，受体不支持该指令时对应群晖型号不会显示。因此，如果DS918+和DVA3221型号没有显示，那是因为CPU不支持MOVBE指令。你可以取消这个限制，并自行承担风险进行测试。

我开发了一个简单的补丁，用于不再显示没有Device-tree型号上的DUMMY端口错误，用户可以安装时无需担心这个问题。

## 快速入门指导

启动加载器后，应该会出现以下屏幕。输入 menu.sh 并按下 `<ENTER>`:

![](doc/first-screen.png)

如果你愿意，也可以通过网页进行访问：

![](doc/ttyd.png)

选择“型号（model）”选项，并选择你偏好的群晖型号：

![](doc/model.png)

选择“版本号（Buildnumber）”选项，并选择第一个选项：

![](doc/buildnumber.png)

进入“序列号（Serial）”菜单，并选择“生成一个随机序列号（Generate a random Serial number）”。

选择“构建（Build）”选项，等待加载器生成：

![](doc/making.png)

选择“启动（Boot）”选项，等待DSM启动：

![](doc/DSM%20boot.png)

由于DSM内核不会在屏幕上显示消息，因此需要通过浏览器访问地址`http://<ip>`来继续配置DSM的过程。
DSM的配置。网上有多个教程介绍如何在互联网上配置DSM，本文不作赘述。


# 教程

一个ARPL用户（Rikkie）创建了一个教程，用于在Proxmox服务器上安装ARPL：
https://hotstuff.asia/2023/01/03/xpenology-with-arpl-on-proxmox-the-easy-way/

# 问题/疑问/等等

如有问题或疑问，请在 https://xpenology.com/forum 上搜索论坛，看是否有类似问题已被讨论和解决。如果找不到解决方案，可使用GitHub issues进行问题反馈。

# 致谢

所有代码均基于TTG、pocopico、jumkey以及其他参与继续TTG原始redpill-load项目的人的工作。

未来将添加更多信息。
