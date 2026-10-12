local renshuang = fk.CreateSkill {
  name = "renshuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["renshuang"] = "纫霜",
  [":renshuang"] = "锁定技，当你的体力值变为1后，复原你的武将牌，然后可以视为使用一张普通锦囊牌（每种牌名每轮限一次）。",

  ["@@renshuang-round"] = "纫霜",
  ["#renshuang-use"] = "纫霜：你可以视为使用一张普通锦囊牌",

  ["$renshuang1"] = "妾这身骨，倒要看看能不能碎在陛下手里！",
  ["$renshuang2"] = "休言蒲柳质弱，韧丝胜金缕。",
}

local spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:reset()
    if player.dead then return end
    local use = room:askToUseVirtualCard(player, {
      name = player:getViewAsCardNames(renshuang.name, Fk:getAllCardNames("t"), nil, player:getTableMark("renshuang-round")),
      skill_name = renshuang.name,
      prompt = "#renshuang-use",
      cancelable = true,
      skip = true,
    })
    if use then
      room:addTableMark(player, "renshuang-round", use.card.trueName)
      room:useCard(use)
    end
  end
}

renshuang:addEffect(fk.HpChanged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and data.num <= 0 and player:hasSkill(renshuang.name) and player.hp == 1
  end,
  on_use = spec.on_use,
})

renshuang:addEffect(fk.HpRecover, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(renshuang.name) and player.hp == 1
  end,
  on_use = spec.on_use,
})

return renshuang
