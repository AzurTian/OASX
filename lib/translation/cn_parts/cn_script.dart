// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_script = {
  I18n.device: '模拟器设置',
  I18n.error: '出错设置',
  I18n.optimization: '优化设置',
  I18n.serial: '模拟器 Serial',
  I18n.serialHelp: '''常见的模拟器 Serial 可以查询下方列表
填 "auto" 自动检测模拟器，多个模拟器正在运行或使用不支持自动检测的模拟器时无法使用 "auto"，必须手动填写

模拟器默认 Serial:
[MuMu模拟器12]: 127.0.0.1:16384 
[MuMu模拟器]: 127.0.0.1:7555 
[雷电模拟器](全系列通用): emulator-5554 或 127.0.0.1:5555

如果没有提及的那可能是还没有测试或者不推荐使用，可以自行尝试
如果你使用了模拟器的多开功能，它们的 Serial 将不是默认的，可以在 console.bat 中执行 `adb devices` 查询，或根据模拟器官方的教程填写''',
  I18n.handle: '句柄 Handle',
  I18n.handleHelp:
      '''填 "auto" 自动检测模拟器，多个模拟器正在运行或使用不支持自动检测的模拟器时无法使用 "auto"，必须手动填写
输入为句柄标题或者是句柄号，每次启动模拟器时句柄号会变化。清空表示不使用window的操作方式。

句柄标题 Handle:
[MuMu模拟器12]: "MuMu模拟器12"
[MuMu模拟器]: "MuMu模拟器" 
[雷电模拟器](全系列通用): "雷电模拟器"

句柄号 Handle:
某些模拟器多开时具有相同的句柄标题（说的就是MuMu），此时需要手动获取模拟器的句柄号手动设置。
获取工具请查阅文档：[模拟器支持]''',
  I18n.packageName: '游戏客户端',
  I18n.packageNameHelp: '模拟器上装有多个游戏客户端时，需要手动选择服务器',
  I18n.screenshotMethod: '模拟器截屏方案',
  I18n.screenshotMethodHelp: '''使用自动选择时，将执行一次性能测试并自动更改为最快的截图方案。一般情况下的速度: 
window_background ~= nemu_ipc >>> DroidCast_raw >  ADB_nc >> DroidCast > uiautomator2 ~= ADB
使用window_background来截图是10ms左右，对比DroidCast_raw是100ms左右（仅限作者的电脑）。但是window_background有一个致命的缺点是模拟器不可以最小化，
nemu_ipc仅限mumu12模拟器且要求版本大于3.8.13，并且需要设置模拟器的执行路径''',
  I18n.controlMethod: '模拟器控制方案',
  I18n.controlMethodHelp:
      '''速度: window_message ~= minitouch > Hermit >>> uiautomator2 ~= ADB
控制方式是模拟人类的速度，也不是越快越好 使用(window_message)会偶尔出现失效的情况''',
  I18n.emulatorinfoType: '模拟器类型',
  I18n.emulatorinfoTypeHelp: '''选择你使用的模拟器类型
            ''',
  I18n.emulatorinfoName: '模拟器名称',
  I18n.emulatorinfoNameHelp: '''示例: MuMuPlayer-12.0-0, 若不清楚请查阅文档
            ''',
  I18n.emulatorWindowMinimize: '启用模拟器窗口最小化',
  I18n.runBackgroundOnly: '启用模拟器仅后台运行',
  I18n.adbRestart: '在检测不到设备的时候尝试重启adb',
  I18n.adbRestartHelp: '',
  I18n.handleError: '启用异常处理',
  I18n.handleErrorHelp: '处理部分异常，运行出错时撤退',
  I18n.saveError: '出错时，保存 Log 和截图',
  I18n.screenshotLength: '出错时，保留最后 X 张截图',
  I18n.notifyEnable: '启用消息推送',
  I18n.notifyConfig: '消息推送配置',
  I18n.notifyConfigHelp: '输入为yaml格式，":"冒号后有一个空格，具体请翻阅文档[消息推送]',
  I18n.screenshotInterval: '放慢截图速度至 X 秒一张',
  I18n.screenshotIntervalHelp: '执行两次截图之间的最小间隔，限制在 0.1 ~ 0.3，对于高配置电脑能降低 CPU 占用',
  I18n.combatScreenshotInterval: '战斗中放慢截图速度至 X 秒一张',
  I18n.combatScreenshotIntervalHelp:
      '执行两次截图之间的最小间隔，限制在 0.1 ~ 1.0，能降低战斗时的 CPU 占用',
  I18n.taskHoardingDuration: '囤积任务 X 分钟',
  I18n.taskHoardingDurationHelp: '能在收菜期间降低操作游戏的频率,任务触发后，等待 X 分钟，再一次性执行囤积的任务',
  I18n.whenTaskQueueEmpty: '当任务队列清空后',
  I18n.whenTaskQueueEmptyHelp: '无任务时关闭游戏，能在收菜期间降低 CPU 占用',
  I18n.scheduleRule: '选择任务调度规则',
  I18n.scheduleRuleHelp: '''这里所指的调度的对象是指Pending中的，Waiting中的任务不属于。
基于过滤器(Filter)的调度：默认的选项，任务的执行顺序会根据开发时所确定的顺序来调度，一般是最优解
基于先来后到(FIFO)的调度：是会按照下次执行时间进行排序，靠前的先执行
基于优先级(Priority)的调度：高优先级先于低优先级执行，同优先级按照先来后到顺序''',
  'emulatorinfo_path': '模拟器路径',
  'emulatorinfo_path_help':
      '举例："E:\\ProgramFiles\\MuMuPlayer-12.0\\shell\\MuMuPlayer.exe"',
};
