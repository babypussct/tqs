local fenchao = fk.CreateSkill{
  name = "fenchao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fenchao"] = "焚巢",
  [":fenchao"] = "限定技，结束阶段，你可以令一名角色获得弃牌堆中的伤害牌（不能超过存活角色数），这些牌造成的伤害改为火焰伤害。",

  ["#fenchao-choose"] = "焚巢：令一名角色获得弃牌堆中的伤害牌！",
  ["@@fenchao-inhand"] = "焚巢",

  ["$fenchao1"] = "袁本初，你一生的心血就此付之一炬吧！",
  ["$fenchao2"] = "这一把火起，定叫他军心大乱！",
}

fenchao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fenchao.name) and player.phase == Player.Finish and
      player:usedSkillTimes(fenchao.name, Player.HistoryGame) == 0 and
      table.find(player.room.discard_pile, function (id)
        return Fk:getCardById(id).is_damage_card
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = fenchao.name,
      prompt = "#fenchao-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = table.filter(room.discard_pile, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    cards = room:tableRandomPick(cards, #room.alive_players)
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, fenchao.name, nil, false, player, "@@fenchao-inhand")
  end,
})

fenchao:addEffect(fk.PreCardUse, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card:getMark("@@fenchao-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fenchaoFire = true
  end,
})

fenchao:addEffect(fk.PreDamage, {
  can_refresh = function(self, event, target, player, data)
    if data.card and data.damageType ~= fk.FireDamage then
      local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      return (card_event.data.extra_data or {}).fenchaoFire
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageType = fk.FireDamage
  end,
})

return fenchao
