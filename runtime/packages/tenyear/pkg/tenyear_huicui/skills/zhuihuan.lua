local zhuihuan = fk.CreateSkill {
  name = "zhuihuan",
}

Fk:loadTranslationTable{
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色：若体力值大于该角色，"..
  "则受到其造成的2点伤害；若体力值不大于该角色，则随机弃置两张手牌。",

  ["#zhuihuan-choose"] = "追还：秘密选择一名角色，直到其准备阶段，此期间对其造成伤害的角色受到伤害或弃牌",

  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
}

zhuihuan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuihuan.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#zhuihuan-choose",
      skill_name = zhuihuan.name,
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(self, {extra_data = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room.logic:getCurrentEvent().id
    local to = event:getCostData(self).extra_data[1]
    if to:getMark(zhuihuan.name) == 0 then
      room:setPlayerMark(to, zhuihuan.name, id)
    end
  end,
})

zhuihuan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark(zhuihuan.name) ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.to == player and damage.from ~= nil and not damage.from.dead then
        table.insertIfNeed(targets, damage.from)
      end

      return false
    end, nil, player:getMark(zhuihuan.name))
    room:setPlayerMark(player, zhuihuan.name, 0)

    if #targets == 0 then
      return false
    end

    local targets1 = table.filter(targets, function (p)
      return p.hp > player.hp
    end)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        if table.contains(targets1, p) then
          room:damage{
            from = player,
            to = p,
            damage = 2,
            skillName = zhuihuan.name,
          }
        else
          local cards = table.filter(p:getCardIds("h"), function (id)
            return not p:prohibitDiscard(id)
          end)
          if #cards > 0 then
            room:throwCard(room:tableRandomPick(cards, 2), zhuihuan.name, p, p)
          end
        end
      end
    end
  end,
})

zhuihuan:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p)
      end,
    })
    return ret
  end,
})

return zhuihuan
