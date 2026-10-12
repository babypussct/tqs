local faqi = fk.CreateSkill {
  name = "faqi",
}

Fk:loadTranslationTable{
  ["faqi"] = "法器",
  [":faqi"] = "出牌阶段，当你使用装备牌后，你可以视为使用一张普通锦囊牌（每回合每种牌名限一次）。",

  ["#faqi-invoke"] = "法器：你可以视为使用一张普通锦囊牌",

  ["$faqi1"] = "脚踏风火轮，金印翻天，剑辟阴阳！",
  ["$faqi2"] = "手执火尖枪，红绫混天，乾坤难困我！",
}

faqi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(faqi.name) and player.phase == Player.Play and
      data.card.type == Card.TypeEquip and
      #player:getViewAsCardNames(faqi.name, Fk:getAllCardNames("t"), nil, player:getTableMark("faqi-turn")) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = player:getViewAsCardNames(faqi.name, Fk:getAllCardNames("t"), nil, player:getTableMark("faqi-turn")),
      skill_name = faqi.name,
      prompt = "#faqi-invoke",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      use.extraUse = true
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self).extra_data)
    room:addTableMark(player, "faqi-turn", use.card.trueName)
    room:useCard(use)
  end,
})

return faqi
