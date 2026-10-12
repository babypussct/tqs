local osKunsi = fk.CreateSkill {
  name = "os__kunsi",
  related_skills = { "os__linglu" },
}

Fk:loadTranslationTable{
  ["os__kunsi"] = "困兕",
  [":os__kunsi"] = "出牌阶段，你可视为对一名未以此法指定过的角色使用【杀】（无次数和距离限制）。" ..
  "若此【杀】未造成伤害，则其拥有〖令戮〗直到你的下个回合开始后。其指定你为〖令戮〗的目标时，可令〖令戮〗的失败结算进行两次。",

  ["#os__kunsi"] = "困兕：视为对一名未指定过的角色使用【杀】（无次数和距离限制）",

  ["$os__kunsi1"] = "豺狼虎兕雄壮，西园将校威风！",
  ["$os__kunsi2"] = "灵帝遗命，岂容尔等放肆？"
}

osKunsi:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#os__kunsi",
  card_num = 0,
  view_as = function(self, player)
    local card = Fk:cloneCard("slash")
    card.skillName = osKunsi.name .. "-tag"
    return card
  end,
  before_use = function(self, player, useData)
    ---@type string
    local skillName = osKunsi.name

    local card = useData.card
    table.removeOne(card.skillNames, skillName .. "-tag")
    card.skillName = skillName
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.os__kunsiUser = player.id
    useData.extraUse = true
    useData.extra_data.os__kunsiTarget = table.map(useData.tos, Util.IdMapper)

    local room = player.room
    table.forEach(useData.tos, function(p)
      room:addPlayerMark(p, "_os__kunsi")
    end)
  end,
})

osKunsi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return scope == Player.HistoryPhase and card and table.contains(card.skillNames, osKunsi.name .. "-tag")
  end,
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, osKunsi.name .. "-tag")
  end,
})

osKunsi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return
      to:getMark("_os__kunsi") > 0 and
      card and
      card.name == "slash" and
      table.contains(card.skillNames, osKunsi.name .. "-tag")
  end,
})

osKunsi:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (data.extra_data or {}).os__kunsiUser == player.id and not data.damageDealt
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = (data.extra_data or {}).os__kunsiTarget

    for _, pid in ipairs(targets) do
      local to = room:getPlayerById(pid)
      room:addTableMarkIfNeed(to, "_os__linglu_jianshuo", player.id)
      if not to:hasSkill("os__linglu") then
        room:handleAddLoseSkills(to, "os__linglu")
        room:addTableMarkIfNeed(player, "_os__linglu", pid)
      end
    end
  end,
})

local osKunsiClear = function(player)
  local room = player.room
  table.forEach(player:getTableMark("_os__linglu"), function(pid)
    local p = room:getPlayerById(pid)
    room:removeTableMark(p, "_os__linglu_jianshuo", player.id)
    room:handleAddLoseSkills(p, "-os__linglu")
  end)

  room:setPlayerMark(player, "_os__linglu", 0)
end

osKunsi:addEffect(fk.TurnStart, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__linglu") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    osKunsiClear(player)
  end,
})

osKunsi:addLoseEffect(function(self, player, isDeath)
  if isDeath then
    osKunsiClear(player)
  end
end)

return osKunsi
