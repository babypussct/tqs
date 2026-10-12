local zisui = fk.CreateSkill {
  name = "ld__zisui",
  derived_piles = "ld__gongsunyuan_infidelity",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__zisui"] = "恣睢",
  [":ld__zisui"] = "锁定技，①摸牌阶段，你多摸X张牌；②结束阶段，若X大于你的体力上限，你死亡（X为“异”的数量）。",

  ["$ld__zisui1"] = "仲达公，敢问这辽隧之战，谁胜谁负啊，哈哈哈哈……",
  ["$ld__zisui2"] = "凡从我大燕者，授印封爵，全族俱荣！",
}

zisui:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zisui.name) or player ~= target then return false end
    if #player:getPile("ld__gongsunyuan_infidelity") > 0 then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + #player:getPile("ld__gongsunyuan_infidelity")
  end,
})

zisui:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zisui.name) or player ~= target then return false end
    return player.phase == Player.Finish and #player:getPile("ld__gongsunyuan_infidelity") > player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:killPlayer({ who = player })
  end,
})

return zisui
