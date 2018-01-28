# AutoBuild





#### BuildVersion更新

```
# build version自动加1
plistCommandPath='/usr/libexec/PlistBuddy'
a=$($plistCommandPath -c "print:CFBundleVersion" './'${TARGET_NAME}'/Supports/Info.plist')
#echo current CFBundleVersion:$a
newValue=$((++a))
#echo update CFBundleVersion: $a
$plistCommandPath -c "set:CFBundleVersion $a" './'${TARGET_NAME}'/Supports/Info.plist'
```



#### 切换证书

```
isCertificateApp=false

echo "~~~~~~~~~~~~~~~~选择打包证书方式~~~~~~~~~~~~~~~~"
echo "        1 certificate1 (默认) "
echo "        2 certificate2"

# 读取用户输入并存到变量里
read certificate
sleep 0.5

# 判读用户是否有输入
if [ -n "$certificate" ]
then
if [ "$certificate" = "1" ]
then
isCertificateApp=false
elif [ "$certificate" = "2" ]
then
isCertificateApp=true
else
echo "参数无效"
exit 1
fi
else
isCertificateApp=false
fi

account="certificate1"

if [ $isCertificateApp = false ]
then
echo '账号1'
cd ./${TARGET_NAME}.xcodeproj/
# sed -i 直接修改源文件，'' 备份文件名, 's/要被取代的字串/新的字串/g', 需要设置bundleID的文件
# 假设com.a.a是测试环境使用的，com.b.b是正式环境使用的
sed -i '' 's/com.lius.newmyapp/com.lius.newmyapp/g' project.pbxproj || exit
sed -i '' 's/AEFB4H53JW/DEF454FS33/g' project.pbxproj || exit
cd ..
echo '* 已更改bundle ID 为：com.lius.newmyapp'
#输出的ipa目录
BUILDPATH=${BUILDPATH}_Certificate1
else
echo '公司账号'
account="KeTao"
cd ./${TARGET_NAME}.xcodeproj/
# sed -i 直接修改源文件，'' 备份文件名, 's/要被取代的字串/新的字串/g', 需要设置bundleID的文件
sed -i '' 's/com.lius.newmyapp/com.lius.newmyapp/g' project.pbxproj || exit
sed -i '' 's/DEF454FS33/AEFB4H53JW/g' project.pbxproj || exit
cd ..
echo '* 已更改bundle ID 为：com.lius.newmyapp'
#输出的ipa目录
BUILDPATH=${BUILDPATH}_Certificate2
fi

IPAPATH=${BUILDPATH}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive

```



#### 自动打包

```
# 清理缓存
xcodebuild clean -workspace ${TARGET_NAME}.xcworkspace -scheme ${TARGET_NAME} -configuration ${CONFIGURATION_TARGET}
# 导出archive文件
xcodebuild archive -workspace ${TARGET_NAME}.xcworkspace -scheme ${TARGET_NAME} -archivePath ${ARCHIVEPATH} -configuration ${CONFIGURATION_TARGET}
# 导出ipa文件，需要注意最后命令用来处理自动验证证书
xcodebuild -exportArchive -archivePath ${ARCHIVEPATH} -exportOptionsPlist ${ExportOptionsPlist} -exportPath ${IPAPATH} -allowProvisioningUpdates

```



#### 验证是否打包成功

```
# 判断是否有文件，然后判断文件大小
# wc -c 计算字节数

IPASize=$(wc -c myapp.ipa  | awk '{print $1}')
echo $IPASize
let minSize=1024*1024*10

if [ $IPASize -gt $minSize ]; then
	echo "ipa 正常"
else
	echo "ipa 不正常"
fi

# 判断文件是否存在
IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa			
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功......"
#open ${BUILDPATH}
else
echo "导出ipa失败......"
exit 1
fi
```



#### fir.im上传

```

# 上传fir
if [ $UPLOADPGYER = true ]
then
echo "~~~~~~~~~~~~~~~~上传ipa到fir~~~~~~~~~~~~~~~~~~~"
#api token 需要用户登录fir.im网站获取
Fir_Api_Token=""
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

```



#### AppStore上传

```

# 上传AppStore

altoolPath='/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool'
"$altoolPath" --validate-app \
-f ${IPAPATH} \
-u ${AppleID} \
-p ${AppleIDPWD} \
-t ios --output-format xml

if [ $? = 0 ]
then
echo "~~~~~~~~~~~~~~~~验证ipa成功~~~~~~~~~~~~~~~~~~~"
"$altoolPath" --upload-app \
-f ${IPAPATH} \
-u ${AppleID} \
-p ${AppleIDPWD} \
-t ios --output-format xml

if [ $? = 0 ]
then
echo "~~~~~~~~~~~~~~~~提交AppStore成功~~~~~~~~~~~~~~~~~~~"
else
echo "~~~~~~~~~~~~~~~~提交AppStore失败~~~~~~~~~~~~~~~~~~~"
fi
fi

```



