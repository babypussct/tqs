local kuiji = fk.CreateSkill {
  name = "v22__kuiji",
}

Fk:loadTranslationTable{
  ["v22__kuiji"] = "溃击",
  [":v22__kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最大的"..
  "一名敌方角色造成2点伤害，其因此进入濒死状态时，体力值最少的一名友方角色回复1点体力。",

  ["#v22__kuiji"] = "溃击：将一张黑色基本牌当【兵粮寸断】对你使用并摸一张牌，然后对体力值最大的敌方造成2点伤害！",
  ["#v22__kuiji-damage"] = "溃击：对体力值最大的敌方角色造成2点伤害！",
  ["#v22__kuiji-recover"] = "溃击：令一名友方角色回复1点体力",

  ["$v22__kuiji1"] = "绝域奋击，孤注一掷。",
  ["$v22__kuiji2"] = "舍得一身剐，不畏君王威。",
}

kuiji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#v22__kuiji",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(kuiji.name, Player.HistoryPhase) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black then
      local card = Fk:cloneCard("supply_shortage")
      card:addSubcard(to_select)
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:useVirtualCard("supply_shortage", effect.cards, player, player, kuiji.name)
    if player.dead then return end
    player:drawCards(1, kuiji.name)
    if player.dead then return end
    local targets = table.filter(player:getEnemies(), function(p)
      return table.every(player:getEnemies(), function(q)
        return q.hp <= p.hp
      end)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#v22__kuiji-damage",
      skill_name = kuiji.name,
      cancelable = true,
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = to[1],
        damage = 2,
        skillName = kuiji.name,
      }
    end
  end,
})

kuiji:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.damage and data.damage.skillName == kuiji.name and not player.dead then
      local skill_event = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
      if skill_event and skill_event.data.skill.name == kuiji.name and skill_event.data.who == player then
        local targets = table.filter(player:getFriends(), function(p)
          return p:isWounded() and table.every(player:getFriends(), function(q)
            return q.hp >= p.hp
          end)
        end)
        if #targets > 0 then
          event:setCostData(self, {extra_data = targets})
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).extra_data
    if #to > 1 then
      to = room:askToChoosePlayers(player, {
        targets = to,
        min_num = 1,
        max_num = 1,
        prompt = "#v22__kuiji-recover::" .. target.id,
        skill_name = kuiji.name,
        cancelable = false,
      })
    end
    room:recover{
      who = to[1],
      num = 1,
      recoverBy = player,
      skillName = kuiji.name,
    }
  end,
})

return kuiji
