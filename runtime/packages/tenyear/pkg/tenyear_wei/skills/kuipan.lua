
local kuipan = fk.CreateSkill {
  name = "kuipan",
  tags = { Skill.Combo },
}

Fk:loadTranslationTable{
  ["kuipan"] = "溃叛",
  [":kuipan"] = "连招技（装备牌+伤害牌），你可以令你与此牌的目标各失去1点体力，然后你摸已损失体力值张牌，"..
  "此牌结算完毕后，你选择此牌的其中一个目标并令所有本回合获得过牌的角色依次选择是否视为对其使用此牌。",

  ["@@kuipan"] = "溃叛 +伤害牌",
  ["#kuipan-invoke"] = "溃叛：是否与目标各失去1点体力，你摸已损失体力值张牌？",
  ["#kuipan-choose"] = "溃叛：选择一名目标角色，本回合获得过牌的角色可以视为对其使用【%arg】",
  ["#kuipan-use"] = "溃叛：是否视为对 %dest 使用【%arg】？",

  ["$kuipan1"] = "",
  ["$kuipan2"] = "",
}

kuipan:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuipan.name) and
      data.card.is_damage_card and not table.contains(data.card.skillNames, kuipan.name) and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[kuipan.name]
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = kuipan.name,
      prompt = "#kuipan-invoke",
    }) then
      event:setCostData(self, { tos = table.connect({ player }, data.tos) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@kuipan", 0)
    local targets = table.simpleClone(data.tos)
    room:sortByAction(targets)
    table.insert(targets, 1, player)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:loseHp(p, 1, kuipan.name, player)
      end
    end
    if player:isWounded() and not player.dead then
      player:drawCards(math.min(player:getLostHp(), 5), kuipan.name)
    end
  end,
})

kuipan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuipan.name) and
      data.card.is_damage_card and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[kuipan.name] and
      table.find(data.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#kuipan-choose:::"..data.card.name,
      skill_name = kuipan.name,
      cancelable = false,
    })[1]
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.to and not move.to.dead and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
          table.insertIfNeed(targets, move.to)
        end
      end
    end, Player.HistoryTurn)
    room:sortByAction(targets)
    local card = Fk:cloneCard(data.card.name)
    card.skillName = kuipan.name
    for _, p in ipairs(targets) do  ---@cast p ServerPlayer
      if not p.dead and p:canUseTo(card, to, { bypass_distances = true, bypass_times = true }) and
        room:askToSkillInvoke(p, {
          skill_name = kuipan.name,
          prompt = "#kuipan-use::"..to.id..":"..data.card.name,
        }) then
        room:useCard{
          from = p,
          tos = { to },
          card = card,
          extraUse = true,
        }
        if to.dead then return end
      end
    end
  end,
})

kuipan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(kuipan.name, true) and
      not table.contains(data.card.skillNames, kuipan.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("@@kuipan") > 0 and data.card.is_damage_card then
      data.extra_data = data.extra_data or {}
      data.extra_data.combo_skill = data.extra_data.combo_skill or {}
      data.extra_data.combo_skill[kuipan.name] = true
    end
    if data.card.type == Card.TypeEquip then
      room:setPlayerMark(player, "@@kuipan", 1)
    else
      room:setPlayerMark(player, "@@kuipan", 0)
    end
  end,
})

return kuipan
