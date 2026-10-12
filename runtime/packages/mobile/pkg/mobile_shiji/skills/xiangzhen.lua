local xiangzhen = fk.CreateSkill {
  name = "xiangzhen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiangzhen"] = "象阵",
  [":xiangzhen"] = "锁定技，【南蛮入侵】对你无效；【南蛮入侵】结算结束后，若此牌造成过伤害，你与伤害来源各摸一张牌。",

  ["$xiangzhen1"] = "象兵便可退敌，何劳本姑娘亲往？",
  ["$xiangzhen2"] = "哼！象阵所至，尽皆纷乱之师。",
}

xiangzhen:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiangzhen.name) and data.card.trueName == "savage_assault" and data.to == player
  end,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})
xiangzhen:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiangzhen.name) and data.card.trueName == "savage_assault" and data.damageDealt
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, xiangzhen.name)
    local players = (data.extra_data or {}).xiangzhen_drawers or Util.DummyTable
    if #players == 0 then return end
    player.room:sortByAction(players)
    for _, p in ipairs(players) do
      if not p.dead then
        p:drawCards(1, xiangzhen.name)
      end
    end
  end,
})
xiangzhen:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and data.card.name == "savage_assault"
  end,
  on_refresh = function(self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      local use = use_event.data
      use.extra_data = use.extra_data or {}
      local xiangzhen_drawers = use.extra_data.xiangzhen_drawers or {}
      table.insertIfNeed(xiangzhen_drawers, player)
      use.extra_data.xiangzhen_drawers = xiangzhen_drawers
    end
  end,
})

return xiangzhen
