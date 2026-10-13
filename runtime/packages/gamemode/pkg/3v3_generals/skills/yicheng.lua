local yicheng = fk.CreateSkill {
  name = "v33__yicheng",
}

Fk:loadTranslationTable{
  ["v33__yicheng"] = "疑城",
  [":v33__yicheng"] = "当己方角色成为敌方角色使用【杀】的目标后，你可以令其摸一张牌，然后其弃置一张手牌；若弃置的是装备牌，则改为其使用之。",

  ["#v33__yicheng-ask"] = "疑城：是否令 %dest 摸一张牌并弃置一张手牌？",
  ["#v33__yicheng-discard"] = "疑城：请弃置一张手牌，若为装备牌则改为使用之",
  ["#v33__yicheng-use"] = "疑城：请使用%arg",

  ["$v33__yicheng1"] = "不怕死，就尽管放马过来！",
  ["$v33__yicheng2"] = "待末将布下疑城，以退曹贼。",
}

yicheng:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yicheng.name) and data.card.trueName == "slash" and
      target:isFriend(player) and data.from:isEnemy(player)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yicheng.name,
      prompt = "#v33__yicheng-ask::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, yicheng.name)
    if not target.dead and not target:isKongcheng() then
      local card = room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yicheng.name,
        cancelable = false,
        prompt = "#v33__yicheng-discard",
        skip = true,
      })
      if #card == 0 then return end
      card = card[1]
      if Fk:getCardById(card).type == Card.TypeEquip then
        room:askToUseRealCard(target, {
          pattern = {card},
          skill_name = yicheng.name,
          prompt = "#v33__yicheng-use:::"..Fk:getCardById(card):toLogString(),
          cancelable = false,
        })
      else
        room:throwCard(card, yicheng.name, target, target)
      end
    end
  end,
})

return yicheng
