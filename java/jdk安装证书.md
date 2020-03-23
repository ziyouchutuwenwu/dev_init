# jdk 安装证书

## 导出证书

- windows 下用 chrome 导出，选择`Base64编码 X.509 (.CER)`

## 安装

- keytool -import -alias linkcity -keystore /usr/lib/jvm/jdk1.8.0_231/jre/lib/security/cacerts -file ~/downloads/xp.cer

## 默认密码

- changeit

## 验证证书

```bash
cd /usr/lib/jvm/jdk1.8.0_231/jre/lib/security
echo 'changeit' | keytool -list -rfc -keystore cacerts
```
