// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _us_base_map = {
  ..._us_ui,
  ..._us_script,
  ..._us_global_game,
  ..._us_restart,
  ..._us_invite_config,
  ..._us_general_battle_config,
  ..._us_switch_soul,
};

final Map<String, String> _us_ui = {
  I18n.logOut: 'Logout',
  I18n.zhCn: '简体中文',
  I18n.enUs: 'English',
  I18n.run: 'Running',
  I18n.pending: 'Pending',
  I18n.waiting: 'Waiting',
  I18n.stop: 'Stopped',
  I18n.warning: 'Warning',
  I18n.connecting: 'Connecting',
  I18n.cancel: 'Cancel',
  I18n.confirm: 'Confirm',
  I18n.retry: 'Retry',
  I18n.selectAll: 'Select all',
  I18n.clear: 'Clear',
  I18n.selectedCount: 'Selected @count',
  I18n.time: 'Time',
  I18n.projectStatement: 'Open Source Software',
  I18n.taskSetting: 'Settings',
  I18n.copy: 'Copy',
  I18n.noData: 'No data',
  I18n.notifyTestHelp:
      'Please refer to the documentation [Message Push] to fill in the relevant configuration',
  I18n.rootPathServerHelp:
      'OASX and OAS are two different things. Do not confuse them, do not put them in the same directory, do not use spaces, do not use Chinese characters, and do not use overly long paths',
  I18n.installOasHelp:
      'This will download and decompress from Github. Please maintain a stable network connection. At the same time, this directory will be cleared',
  I18n.configUpdateTip:
      'The current script is running, please stop it before making modifications.',
  I18n.minimizeToSystemTrayHelp:
      'Minimized to the system tray when closing a window',
  I18n.launchAtStartupHelp: 'Launch OASX when you sign in',
  I18n.launchAtStartupUpdateFailed: 'Failed to update launch at startup',
  I18n.scriptList: 'Configs',
  I18n.loginAddress: 'Login address',
  I18n.username: 'Username',
  I18n.password: 'Password',
  I18n.userSetting: 'User settings',
  I18n.homeSelectControlScript: 'Select control scripts',
  I18n.homeOverviewControl: 'Overview and control',
  I18n.homeMasterSwitch: 'Master switch',
  I18n.homeRunningCount: 'Running: @running / @total',
  I18n.homeTotalScripts: 'Total scripts',
  I18n.homeControlScriptCount: 'Control scripts: @count',
  I18n.turnOnTheLinker: 'Turn on the linker',
  I18n.closeTheLinker: 'Close the linker',
  I18n.homeNoTask: 'No tasks',
  I18n.homeNoLog: 'No logs yet',
  I18n.homeUnconfiguredTask: 'No tasks, please configure the script first',
  I18n.homeRunningTask: 'Running task',
  I18n.homePendingTask: 'Pending task',
  I18n.homeWaitingTask: 'Waiting task',
  I18n.homeConnectionRetryHint:
      'Please confirm the backend service has started and user settings are correct',
  I18n.homeConnectionRetryAction: 'Refresh',
  I18n.homeEmptyScriptHint: 'Add a config first',
  I18n.homeLoadingAutoDeploying: 'Auto deployment in progress, please wait',
  I18n.homeLoadingAutoLogin: 'Logging into OAS, please wait',
  I18n.homeLoadingConfigDetail: 'Loading config details, please wait',
  I18n.homeScriptAbnormal: 'Abnormal',
  I18n.homeScriptOffline: 'Offline',
  I18n.homeScriptSearchHint: 'Search configs',
  I18n.homeSortByStatus: 'Sort by status',
  I18n.homeSortByName: 'Sort by name',
  I18n.homeNoScriptSelected: 'Select a config first',
  I18n.homeStatusTab: 'Status',
  I18n.homeTasksTab: 'Tasks',
  I18n.homeStatsTab: 'Stats',
  I18n.homeParamsTab: 'Params',
  I18n.homeStatsGeneratedAt: 'Generated at',
  I18n.homeStatsRetentionDays: 'Retention days',
  I18n.homeStatsToday: 'Today',
  I18n.homeStatsSelectedDate: 'Selected date',
  I18n.homeStatsTasks: 'Tasks',
  I18n.homeStatsRunCount: 'Runs',
  I18n.homeStatsTotalDuration: 'Total runtime',
  I18n.homeStatsBattleCount: 'Battles',
  I18n.homeStatsBattleTotalDuration: 'Total battle duration',
  I18n.homeStatsBattleAvgDuration: 'Avg battle duration',
  I18n.homeStatsAvgRunDuration: 'Avg run duration',
  I18n.homeStatsMetricRunCount: 'Run count',
  I18n.homeStatsMetricBattleCount: 'Battle count',
  I18n.homeStatsMetricBattleAvgDuration: 'Avg battle duration',
  I18n.homeStatsMetricAvgRunDuration: 'Avg runtime',
  I18n.homeStatsWaitingSnapshot: 'Waiting for statistics snapshot',
  I18n.homeStatsConnected: 'Stats stream connected',
  I18n.homeStatsDisconnected: 'Stats stream disconnected',
  I18n.homeStatsReconnecting: 'Stats stream reconnecting',
  I18n.homeStatsStreamError: 'Stats stream error',
  I18n.homeStatsTimelineEmpty: 'No timeline data for today yet',
  I18n.homeStatsChartEmpty: 'No chart data for the selected day',
  I18n.homeStatsTaskDetails: 'Task details',
  I18n.homeStatsTaskDetailEmpty: 'No run details for the focused task',
  I18n.homeStatsNoTaskSelected: 'Select a task first',
  I18n.homeStatsExtensionsEmpty: 'No extension fields for this task',
  I18n.homeStatsDuration: 'Duration',
  I18n.homeStatsTodayChartTitle: 'Today task timeline',
  I18n.homeStatsHistoryChartTitle: 'Historical task chart',
  I18n.homeStatsTodayChartEmpty: 'No realtime task blocks for today yet',
  I18n.homeStatsHistoryDateEmpty: 'No historical date is available yet',
  I18n.homeStatsLatestTask: 'Latest task',
  I18n.homeStatsLatestTime: 'Latest time',
  I18n.homeStatsCurrentTask: 'Current task',
  I18n.homeStatsCurrentTime: 'Current time',
  I18n.homeStatsIdle: 'Idle',
  I18n.homeStatsStartTime: 'Start time',
  I18n.homeStatsTaskFilter: 'Task filter',
  I18n.homeStatsAllTasks: 'All tasks',
  I18n.homeStatsRunDetails: 'Run details',
  I18n.homeStatsSelectedBlock: 'Selected block',
  I18n.homeStatsLoadingMessage: 'Collecting statistics, please wait',
  I18n.homeStatsSummaryRunDuration: 'Runtime',
  I18n.homeStatsSummaryRunTaskCount: 'Task total',
  I18n.homeStatsSummaryTotalBattleCount: 'Battle total',
  I18n.homeStatsSortByData: 'Data',
  I18n.homeStatsSortByTime: 'Time',
  I18n.homeStatsNoBattle: 'No battle',
  I18n.homeTaskFilterAll: 'All tasks',
  I18n.homeTaskFilterEnabled: 'Enabled',
  I18n.homeTaskFilterDisabled: 'Disabled',
  I18n.homeTaskEnabled: 'Enabled',
  I18n.homeTaskDisabled: 'Disabled',
  I18n.homeQuickRun: 'Run now',
  I18n.homeQuickWait: 'Wait now',
  I18n.homeOpenTaskParams: 'Edit',
  I18n.homeTaskConfigureAndEnable: 'Configure and enable',
  I18n.homeTaskSelectPrompt: 'Select a task from the task list first',
  I18n.homeRealtimeLog: 'Realtime',
  I18n.homeHistoryLog: 'History',
  I18n.homeLogSearchHint: 'Search logs or enter regex',
  I18n.homeLogUseRegex: 'Regex',
  I18n.homeLogWrapLines: 'Wrap lines',
  I18n.homeLogAutoScroll: 'Auto-scroll',
  I18n.homeLogLoadOlder: 'Load older',
  I18n.homeLogEmptyFiltered: 'No matching logs',
  I18n.argsDraftDirty: 'Pending changes',
  I18n.argsMixedValue: 'Mixed value',
  I18n.argsDiscardChanges: 'Discard',
  I18n.argsSaveChanges: 'Save',
  I18n.argsValidationFailed: 'Fix validation errors before saving',
  I18n.argsInvalidInteger: 'Enter a valid integer',
  I18n.argsInvalidNumber: 'Enter a valid number',
  I18n.argsInvalidTime: 'Time must use HH:MM:SS',
  I18n.argsInvalidTimeDelta: 'Duration must use DD HH:MM:SS',
  I18n.argsInvalidDateTime: 'Date time must use YYYY-MM-DD HH:MM:SS',
  I18n.argsInvalidEnum: 'Select a valid option',
  I18n.argsMinValue: 'Min value',
  I18n.argsMaxValue: 'Max value',
  I18n.argsUnsavedPrompt: 'There are unsaved changes. Discard them?',
  I18n.taskManage: 'Task Manager',
  I18n.taskManageTitle: 'Task Manager',
  I18n.taskSearchHint: 'Search tasks',
  I18n.taskNotFound: 'No matching tasks',
  I18n.taskMenuLoadFailed: 'Failed to load task menu',
};

final Map<String, String> _us_script = {
  I18n.serialHelp: '''Common emulator serials can be found in the list below. 
Fill in "auto" to automatically detect the emulator. When multiple emulators are running or an emulator that does not support automatic detection is used, "auto" cannot be used and must be filled in manually.
  
Default emulator serials: 
[MuMu Player 12]: 127.0.0.1:16384 
[MuMu Player]: 127.0.0.1:7555 
[LDPlayer](all series): emulator-5554 or 127.0.0.1:5555
If it's not mentioned, it may not have been tested or is not recommended. You can try it yourself. 
If you use the multi-instance function of the emulator, their serials will not be the default. You can query them by executing adb devices in console.bat, or fill them in according to the official emulator tutorial''',
  I18n.handleHelp:
      '''Fill in "auto" to automatically detect the emulator. "auto" cannot be used when multiple emulators are running or when using an emulator that does not support automatic detection; it must be filled in manually. The input is the handle title or handle number. The handle number changes each time the emulator is started. Clearing it means not using the window operation method.

Handle Title: 
[MuMu Player 12]: "MuMu Player 12" 
[MuMu Player]: "MuMu Player" 
[LDPlayer](all series): "LDPlayer"

Handle Number: 
Some emulators have the same handle title when multiple instances are opened (referring to MuMu). In this case, you need to manually obtain the emulator's handle number and set it manually. 
Please refer to the documentation for tools to obtain it: [Emulator Support]''',
  I18n.packageNameHelp:
      'When multiple game clients are installed on the emulator, you need to manually select the server',
  I18n.screenshotMethodHelp:
      '''When automatic selection is used, a performance test will be performed once, and it will automatically change to the fastest screenshot solution. The general speed is: 
window_background ~= nemu_ipc >>> DroidCast_raw > ADB_nc >> DroidCast > uiautomator2 ~= ADB 
Using window_background for screenshots is about 10ms, compared to DroidCast_raw which is about 100ms (only on the author's computer). However, window_background has a fatal flaw: the emulator cannot be minimized. 
nemu_ipc is limited to MuMu Player 12 and requires a version greater than 3.8.13, and the emulator's execution path needs to be set''',
  I18n.controlMethodHelp:
      '''Speed: window_message ~= minitouch > Hermit >>> uiautomator2 ~= ADB 
The control method simulates human speed, and faster is not always better. Using (window_message) may occasionally fail''',
  I18n.emulatorinfoTypeHelp: '''Select the type of emulator you are using''',
  I18n.emulatorinfoNameHelp:
      '''Example: MuMuPlayer-12.0-0, if unclear, please consult the documentation''',
  I18n.adbRestartHelp: '',
  I18n.notifyConfigHelp:
      'Input is in YAML format, there is a space after the colon ":", for details please refer to the documentation [Message Push]',
  I18n.screenshotIntervalHelp:
      'The minimum interval between two screenshots, limited to 0.1 ~ 0.3, can reduce CPU usage for high-configuration computers',
  I18n.combatScreenshotIntervalHelp:
      'The minimum interval between two screenshots, limited to 0.1 ~ 1.0, can reduce CPU usage during battles',
  I18n.taskHoardingDurationHelp:
      'Can reduce the frequency of game operations during farming periods. After a task is triggered, wait X minutes, then execute the accumulated tasks all at once',
  I18n.whenTaskQueueEmptyHelp:
      'Close the game when there are no tasks, which can reduce CPU usage during farming periods',
  I18n.scheduleRuleHelp:
      '''The scheduling objects referred to here are those in Pending; tasks in Waiting are not included. 
Filter-based scheduling: The default option. The execution order of tasks will be scheduled according to the order determined during development, which is generally the optimal solution. 
First-In, First-Out (FIFO)-based scheduling: Tasks will be sorted by their next execution time, and those at the front will be executed first. 
Priority-based scheduling: High-priority tasks are executed before low-priority tasks. Tasks with the same priority are executed in a first-come, first-served order''',
  'emulatorinfo_path_help':
      'Example: "E:\\ProgramFiles\\MuMuPlayer-12.0\\shell\\MuMuPlayer.exe"',
};

final Map<String, String> _us_restart = {
  I18n.enableHelp: 'Add this task to the scheduler',
  I18n.nextRunHelp:
      'The time will be automatically calculated based on the interval below',
  I18n.priorityHelp:
      'This option is valid if the scheduling rule is set to priority-based. The default is 5. The lower the number, the higher the priority. The range is [1-15]. If the priority is the same, tasks are scheduled on a first-come, first-served basis',
  I18n.successIntervalHelp: '',
  I18n.failureIntervalHelp: '',
  I18n.serverUpdateHelp:
      'If it\'s not set to the default "09:00:00", the task will forcibly set the next run time to the set value of the next day after each execution',
  I18n.harvestEnableHelp:
      'This section is for automatically clicking on login rewards when logging into the game. It is a required option',
  'rest_task_datetime_help': '',
  'delay_date_help':
      'When the forced execution time is enabled above, customize how many days later to enforce execution. By default, it\'s one day later, meaning the next day',
  'float_time_help':
      'To prevent account suspension, the next run time will be randomly delayed within this range; generally, three to five minutes is sufficient. When forced execution is enabled, ensure it does not exceed the window: for example, Kirin at 19:00 + 2 minutes, Demon Encounter at 17:00 + 1.5 hours, to avoid affecting other tasks',
};

final Map<String, String> _us_global_game = {
  I18n.friendInvitationHelp: 'Accept all by default',
  'accept_invitation_complete_now_help':
      'To prevent cancellation by the other party due to two hours of inactivity, it is enabled by default',
  I18n.invitationDetectIntervalHelp:
      'Detect collaboration every 10 seconds by default',
  I18n.whenNetworkAbnormalHelp: 'By default, it will wait for 10 seconds first',
  I18n.whenNetworkErrorHelp: 'Restart the game',
  I18n.homeClientClearHelp:
      'Sometimes it may require clearing the cache when entering the courtyard',
  I18n.enableHelp: 'Add this task to the scheduler',
  I18n.brokerHelp: '',
  I18n.portHelp: '',
  I18n.transportHelp: '',
  I18n.caHelp: '',
  I18n.usernameHelp: '',
  I18n.passwordHelp: '',
  // ---------------------------------------------------------------------
  'costume_main': 'On Tranquil Views',
  'costume_main_1': 'Celestial Garden',
  'costume_main_2': 'Luminescent Night',
  'costume_main_3': 'Melodic Pavilion',
  'costume_main_4': 'Painted Panorama',
  'costume_main_5': 'Autumn Maples',
  'costume_main_6': 'Hot Spring',
  'costume_main_7': 'Summer Nights',
  'costume_main_8': 'Far-sailing Ship',
  // ---------------------------------------------------------------------
  'costume_realm_default': 'Umbrella Sanctuary',
  'costume_realm_1': 'Demon Spirit Charms',
  'costume_realm_2': 'Fox\'s Defensive Realm',
  'costume_realm_3': 'Threaded Memories',
  'costume_realm_4': 'Sea of Flowers',
  // ---------------------------------------------------------------------
  'costume_battle_1': 'Realm of Melodies',
};

final Map<String, String> _us_invite_config = {
  'invite_number_help':
      'This is effective when you are the team leader. You can choose 1 or 2. If you choose 1, only the first teammate will be invited',
  'friend_name_help':
      'When inputting your teammate\'s name, it must be the full name. This is based on OCR recognition, so if the name is too unusual, it\'s recommended to spend 200 Jade to change it to something more standard',
  'friend_2_name_help': 'Same as above',
  'find_mode_help':
      'By default, it will automatically search from the list above: \n"Friend" -> "Recent" -> "Guildmate" -> "Cross-server". Of course, it is recommended to select ‘recent_friend’ as this will be faster',
  'wait_time_help':
      'Keep the default setting for one minute, and invite once every 20 seconds during this period',
  'default_invite_help': '',
};

final Map<String, String> _us_general_battle_config = {
  'lock_team_enable_help':
      'If the team is locked, preset teams and buff features cannot be enabled',
  'preset_enable_help':
      'The team preset will be switched during the first battle',
  'preset_group_help': 'Select[1~7]',
  'preset_team_help': 'Select[1~5]',
  'green_enable_help':
      'Click the green mark at the moment the battle starts, with no feedback on the click',
  'green_mark_help':
      'Select from [Left 1, Left 2, Left 3, Left 4, Left 5, Main Onmyoji]',
  'random_click_swipt_enable_help':
      'Anti-blocking optimization: may trigger 0-8 times in every three minutes of battle. Please note that this conflicts with the green mark function and may cause random clicks on the green mark',
};

final Map<String, String> _us_switch_soul = {
  'switch_group_team_help':
      '''The initial value is not suitable; you need to set it according to your own situation. 
'1,2' indicates the first preset group and the second team. 
Please use a comma from the English input method. 
Preset groups support [1-7], and preset teams support [1-4]''',
  'enable_switch_by_name_help':
      'This is another way to switch souls. Compared to the method above, it supports more presets, but similarly, you still need to ensure that the preset team is in a locked state',
};
