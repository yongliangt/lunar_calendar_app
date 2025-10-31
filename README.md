农历提醒日历 Flutter 项目

这是一个Flutter入门项目，用于演示如何构建一个支持农历提醒的日历应用。

文件保存位置

这是一个标准的Flutter项目结构。您应该按如下方式组织文件：

pubspec.yaml:

位置: 项目的根目录 (/pubspec.yaml)。

内容: 包含所有Flutter和Dart的依赖项，如 table_calendar, hive, flutter_local_notifications 等。

main.dart:

位置: lib/ 文件夹 (/lib/main.dart)。

内容: 这是应用的主入口点。为方便演示，所有的Dart代码（包括模型、服务和UI屏幕）都已合并到这一个文件中。

build.gradle:

位置: Android特定的配置，位于 android/app/ 文件夹 (/android/app/build.gradle)。

内容: 在这个文件中，compileSdkVersion 和 targetSdkVersion 已被设置为 35，以确保与 Android 15 兼容。

AndroidManifest.xml:

位置: Android特定的清单文件，位于 android/app/src/main/ 文件夹 (/android/app/src/main/AndroidManifest.xml)。

内容: 添加了必要的权限，特别是 POST_NOTIFICATIONS (Android 13+) 和 SCHEDULE_EXACT_ALARM (Android 14+)，这对于提醒功能至关重要。

README.md (本文件):

位置: 项目的根目录 (/README.md)。

如何运行

创建项目:

flutter create lunar_calendar_app


替换文件:

将您新创建的 lunar_calendar_app 文件夹中的 pubspec.yaml 替换为上面提供的 pubspec.yaml。

进入 lib/ 目录，将 main.dart 替换为上面提供的 main.dart。

进入 android/app/ 目录，将 build.gradle 替换为上面提供的 build.gradle。

进入 android/app/src/main/ 目录，将 AndroidManifest.xml 替换为上面提供的 AndroidManifest.xml。

获取依赖:

flutter pub get


运行应用:

flutter run


重要提示: 此代码使用 Hive 数据库。在您第一次运行应用时，如果遇到 HiveBox 未打开的错误，请完全停止应用并重新启动它。