-- 智能输入法切换（接线层）。
--
-- 判断逻辑已经拆到 lua/modules/im/ 下：
--   modules/im/backend.lua    设备后端（ibus / fcitx5 / 大写锁定），只管读和设
--   modules/im/container.lua  treesitter 容器识别（代码/注释/字符串/公式/URL）
--   modules/im/fallback.lua   没有 parser 时的最小词法兜底
--   modules/im/evidence.lua   容器内文本 → 中英证据（纯函数）
--   modules/im/decide.lua     分层决策 + 迟滞 + 会话记忆
--   modules/im/init.lua       自动命令接线、指示器
--
-- 设计要点：只在「进入插入模式」和「容器类别变化」时判断；普通模式保持英文；
-- 插入模式用的语言会被记住，用户手动切过则一段时间内不抢。

require("modules.im").setup({
	indicator = true,
	tau = 0.8,
	manual_ttl_ms = 60000,
})
