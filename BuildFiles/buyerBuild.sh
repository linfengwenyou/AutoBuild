#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"

# 返回上一级
cd ..

# 更新
git pull

DATE=`date '+%Y-%m-%d-%T'`
#需要编译的 targetName
TARGET_NAME="myBuyer"
#编译模式 工程默认有 Debug Release
CONFIGURATION_TARGET=Release
#编译路径                   路径需要根据自己需要调整
BUILDPATH=~/FMProjects/builds/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}

# build version自动加1
plistCommandPath='/usr/libexec/PlistBuddy'
a=$($plistCommandPath -c "print:CFBundleVersion" './'${TARGET_NAME}'/Supports/Info.plist')
#echo current CFBundleVersion:$a
newValue=$((++a))
#echo update CFBundleVersion: $a
$plistCommandPath -c "set:CFBundleVersion $a" './'${TARGET_NAME}'/Supports/Info.plist'

#导出ipa 所需plist
ADHOCExportOptionsPlist=./BuildFiles/ADHOCExportOptionsPlist.plist
AppStoreExportOptionsPlist=./BuildFiles/AppStoreExportOptionsPlist.plist
DevelopmentExportOptionsPlist=./BuildFiles/DevelopmentExportOptionsPlist.plist

ExportOptionsPlist=${DevelopmentExportOptionsPlist}

# 是否上传fir
UPLOADPGYER=false

echo "~~~~~~~~~~~~~~~~选择打包方式~~~~~~~~~~~~~~~~"
echo "        1 Developer (默认) "
echo "        2 ad-hoc"

# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
if [ "$method" = "1" ]
then
ExportOptionsPlist=${DevelopmentExportOptionsPlist}
elif [ "$method" = "2" ]
then
ExportOptionsPlist=${ADHOCExportOptionsPlist}
else
echo "参数无效"
exit 1
fi
else
ExportOptionsPlist=${DevelopmentExportOptionsPlist}
fi

echo "~~~~~~~~~~~~~~~~是否上传fir~~~~~~~~~~~~~~~~"
echo "        1 不上传 (默认)"
echo "        2 上传 "

read para
sleep 0.5

if [ -n "$para" ]
then
if [ "$para" = "1" ]
then
UPLOADPGYER=false
elif [ "$para" = "2" ]
then
UPLOADPGYER=true
else
echo "参数无效...."
exit 1
fi
else
UPLOADPGYER=false
fi


xcodebuild clean -workspace ${TARGET_NAME}.xcworkspace -scheme ${TARGET_NAME} -configuration ${CONFIGURATION_TARGET}
xcodebuild archive -workspace ${TARGET_NAME}.xcworkspace -scheme ${TARGET_NAME} -archivePath ${ARCHIVEPATH} -configuration ${CONFIGURATION_TARGET}

echo "~~~~~~~~~~~~~~~~导出ipa~~~~~~~~~~~~~~~~~~~"


xcodebuild -exportArchive -archivePath ${ARCHIVEPATH} -exportOptionsPlist ${ExportOptionsPlist} -exportPath ${IPAPATH} -allowProvisioningUpdates

echo "~~~~~~~~~~~~~~~~检查是否成功导出ipa~~~~~~~~~~~~~~~~~~~"

IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功......"
#open ${BUILDPATH}
else
echo "导出ipa失败......"
exit 1
fi


# 上传fir
if [ $UPLOADPGYER = true ]
then
echo "~~~~~~~~~~~~~~~~上传ipa到fir~~~~~~~~~~~~~~~~~~~"
#api token 需要用户登录fir.im网站获取
Fir_Api_Token="aad7c38bc2b209036e600d3217e8a46c"
fir p $IPAPATH -T $Fir_Api_Token

if [ $? = 0 ]
then
echo "~~~~~~~~~~~~~~~~上传fir成功~~~~~~~~~~~~~~~~~~~"
else
echo "~~~~~~~~~~~~~~~~上传fir失败,请手动上传~~~~~~~~~~"
open ${BUILDPATH}
fi
else
open ${BUILDPATH}
fi

echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
echo "currentBundleVersion: $a"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "导出ipa配置: ${ExportOptionsPlist}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "导出ipa路径: ${IPAPATH}"

exit 1

