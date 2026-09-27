# react_native

## 说明

支持 发布为 ios, android，不支持小程序

## 用法

创建项目

```sh
npx create-expo-app@latest --template
```

android 下运行，需要本地配置如下环境变量

```sh
export ANDROID_HOME=$HOME/dev/android/sdk/
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

npm run android
```

## 打包

```sh
# 参考 https://docs.expo.dev/build/setup/
eas login
eas build:configure

# 打包为 apk， 需要修改 eas.json
# 参考 https://docs.expo.dev/build-reference/apk/
eas build -p android --profile xxx

# 打包为 aab, 不能在手机上直接装
eas build --platform android
```

## 环境变量

环境变量必须以 `EXPO_PUBLIC_` 开头

[参考链接](https://docs.expo.dev/build-reference/variables/)

eas.json

```json
{
  "build": {
    "production": {
      "env": {
        "EXPO_PUBLIC_MY_ENV": "https://api.production.com"
      },
      "android": {
        "buildType": "apk"
      }
    },
    "test": {
      "env": {
        "EXPO_PUBLIC_MY_ENV": "https://api.test.com"
      },
      "android": {
        "buildType": "apk"
      }
    }
  }
}
```

.env

```sh
# 环境变量 fall back
EXPO_PUBLIC_MY_ENV=http://api.local
```

App.tsx

```typescript
import { StatusBar } from "expo-status-bar";
import { StyleSheet, Text, View } from "react-native";

export default function App() {
  const myenv = process.env.EXPO_PUBLIC_MY_ENV;
  return (
    <View style={styles.container}>
      <Text>process.env is {myenv}</Text>
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
});
```
