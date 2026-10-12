--注册一些通用的TargetTip

-- 用于增加/减少目标的选人函数的TargetTip
-- extra_data:
-- targets integer[] @ 可选的玩家id数组
-- extra_data integer[] @ 卡牌的当前目标，是玩家id数组
Fk:addTargetTip{
  name = "addandcanceltarget_tip",
  target_tip = function(_, _, to_select, _, _, _, _, extra_data)
    if not table.contains(extra_data.targets, to_select.id) then return end
    if type(extra_data.extra_data) == "table" then
      if table.contains(extra_data.extra_data, to_select.id) then
        return { {content = "@@CancelTarget", type = "warning"} }
      else
        return { {content = "@@AddTarget", type = "normal"} }
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["@@AddTarget"] = "增加目标",
  ["@@CancelTarget"] = "取消目标",
}
