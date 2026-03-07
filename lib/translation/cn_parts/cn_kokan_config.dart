// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_kokan_config = {
  'Dokan': '道馆',
  'dokan_config': '道馆配置',
  'dokan_attack_priority': '攻击优先顺序',
  'dokan_attack_priority_help': '见习=0,初级=1...',
  'dokan_auto_cheering_while_cd': '失败CD后自动加油',
  'dokan_auto_cheering_while_cd_help': '',
  'anti_detect_click_fixed_random_area': '点击固定随机区域',
  'anti_detect_click_fixed_random_area_help':
  '防封使用固定的随机区域进行随机点击, 若不启用将自动识别当前画面中的最大纯色区域作为随机点击区域',
  'monday_to_thursday': '周一到周四',
  'monday_to_thursday_help': '是否只在周一到周四开启道馆',
  'try_start_dokan': '尝试开启道馆',
  'try_start_dokan_help': '在道馆未开启状态下，是否查找道馆并开启。没有权限不建议开启',
  'find_dokan_score': '道馆系数',
  'dokan_score_help': '赏金与人数的比值，查找道馆时，最大道馆系数，只开启低于此系数的道馆',
  'min_people_num': '最少人数',
  'min_people_num_help': '开启道馆的最少人数',
  'min_bounty': '最少赏金',
  'min_bounty_help': '开启道馆的最少赏金',
  'find_dokan_refresh_count': '道馆列表最大刷新次数',
  'find_dokan_refresh_count_help':
  '单次查找道馆过程中，最大刷新次数。若超过此次数，会随机在当前显示的列表中(3-4个)选择系数最低的',
  'switch_preset_enable': '开启切换预设队伍',
  'switch_preset_enable_help': '不建议使用通用战斗设置中的切换预设队伍',
  'preset_group_1': '馆员阵容',
  'preset_group_1_help': '打除馆主外的人时，使用的阵容,格式：3,2 ,表示第三组，第二个队伍,取值范围与其他设置预设队伍相同',
  'preset_group_2': '馆主阵容',
  'preset_group_2_help': '打馆主时使用的阵容,格式同上',
  'green_mark_shikigami_name': '式神名绿标',
  'green_mark_shikigami_name_help': '根据式神自定义名称进行绿标，多个式神名可用英文逗号,分隔;',
  'attack_count_config': '攻击数量设置',
  'remain_attack_count': '剩余攻击次数',
  'remain_attack_count_help': '用于记录当前剩余攻击次数。一般情况下，此值无须手动修改',
  'attack_date': '记录时间',
  'attack_date_help': '剩余攻击次数的时间有效期,即 该时间剩余攻击次数为 .一般情况下，此值无须手动修改',
  'daily_attack_count': '每日道馆次数',
  'daily_attack_count_help':
  '僵尸寮比较有用，正常的保持2即可.每天要打两次道馆的，两次道馆时间间隔由 调度器中 [失败后设定经过X时间后执行]确定',
  'attack_dokan_master': '攻打馆主策略',
  'attack_dokan_master_help':
  '僵尸寮比较有用,一般的保持TWO_TWO即可.两次道馆，ONE/TWO表示打馆主的第一/第二阵容。僵尸寮建议ZERO_TWO',
};


