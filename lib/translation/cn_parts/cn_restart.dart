// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_restart = {
  I18n.harvestConfig: '收菜配置',
  I18n.enable: '启用该功能',
  I18n.enableHelp: '将这个任务加入调度器',
  I18n.nextRun: '下一次运行时间',
  I18n.nextRunHelp: '会根据下面的间隔时间自动计算时间',
  I18n.priority: '任务优先级',
  I18n.priorityHelp:
      '如果设置调度规则为基于优先级，则该选项有效，默认为5，数字越低优先级越高，可取[1~15],如果同优先级,则按照先来后到规则进行调度',
  I18n.successInterval: '执行任务成功后设定经过 X 时间后执行',
  I18n.successIntervalHelp: '',
  I18n.failureInterval: '执行任务失败后设定经过 X 时间后执行',
  I18n.failureIntervalHelp: '',
  I18n.serverUpdate: '强制设定服务执行时间',
  I18n.serverUpdateHelp: '如果设定不是默认的 "09:00:00",该任务每次执行完毕后会强制设定下次运行时间为第二天的设定值',
  I18n.harvestEnableHelp: '这个一个部分是为了在登录游戏时，自动点击赠送的奖励，是必选项',
  I18n.enableJade: '永久勾玉卡',
  I18n.enableSign: '每日签到',
  I18n.enableSign999: '签到999天后的签到福袋',
  I18n.enableMail: '邮件',
  I18n.enableSoul: '御魂或者觉醒加成',
  I18n.enableAp: '体力',
  'tasks_config_reset': '重置所有计划任务',
  'reset_task_datetime_enable': '重置所有任务的下一次运行时间',
  'reset_task_datetime_enable_help': '勾选立即执行，记得反选掉',
  'reset_task_datetime': '重设的时间',
  'rest_task_datetime_help': '',
  'float_time': '随机延迟时间',
  'delay_date': '强制日期间隔',
  'delay_date_help': '启用上方强制设定执行时间时，自定义几天后强制执行，默认一天后即第二天',
  'float_time_help':
      '防封，下次运行时间将在此范围内随机延迟，一般三五分钟即可。有强制执行时，确保不超出窗口：如麒麟19:00+2分钟，逢魔17:00+1.5小时，避免影响其他任务',
};
