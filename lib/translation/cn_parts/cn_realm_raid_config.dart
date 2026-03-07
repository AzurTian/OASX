// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_realm_raid_config = {
  'number_attack': '挑战次数',
  'number_attack_help': '默认30，可选范围[1~30]，没有挑战卷自动退出任务（标记为成功）',
  'number_base': '突破卷数量大于等于 X 时才会挑战',
  'number_base_help': '旨在检查突破卷数量，如果当前的数量没有大于等于这个值，将标记为成功并退出， 可选值[0~20]',
  'exit_four': '当进攻到左上角第一个的时候先退四次再进攻',
  'exit_four_help': '为了支持打九退四，保证稳定57级',
  'order_attack': '挑战顺序',
  'order_attack_help': '使用过滤器，保持默认即可',
  'three_refresh': '每三次就刷新',
  'three_refresh_help': '挑战进度到三，领取奖励后就刷新，如果刷新操作进入CD，将标记为失败并退出',
  'when_attack_fail': '挑战失败时',
  'when_attack_fail_help': '''Exit：直接退出任务，标记为失败
Continue：挑战其他的直至没有可挑战的才刷新
Refresh：直接刷新，如果刷新操作进入CD，将标记为失败并退出''',
};


