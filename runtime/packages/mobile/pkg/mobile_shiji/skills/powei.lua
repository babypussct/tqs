local powei = fk.CreateSkill {
  name = "powei",
  tags = { Skill.Quest },
  related_skills = { "shenzhuo" },
}

Fk:loadTranslationTable{
  ["powei"] = "破围",
  [":powei"] = "使命技，游戏开始时，你令所有其他角色获得“围”标记；回合开始时，你令所有拥有“围”标记的角色将“围”标记移动至下家"..
  "（若下家为你，则改为移动至你的下家）；有“围”标记的角色受到伤害后，移去其“围”标记；有“围”的角色的回合开始时，你可以选择一项并"..
  "令你本回合视为处于其攻击范围内：1.弃置一张手牌，对其造成1点伤害；2.若其体力值不大于你，你获得其一张手牌。<br>"..
  "⬤　成功：回合开始时，若场上没有“围”标记，则你获得技能〖神著〗；<br>"..
  "⬤　失败：当你进入濒死状态时，若你的体力值小于1，你回复体力至1点，移去场上所有的“围”标记，然后弃置你装备区里所有的牌。",

  ["@@powei_wei"] = "围",
  ["powei_damage"] = "弃一张手牌，对其造成1点伤害",
  ["powei_prey"] = "获得其一张手牌",
  ["#powei-invoke"] = "破围：你可以对 %dest 执行一项",

  ["$powei1"] = "君且城中等候，待吾探敌虚实。",
  ["$powei2"] = "弓马骑射洒热血，突破重围显英豪！",
  ["$powei3"] = "敌军尚犹严防，有待明日再看！",
}

powei:addAuxActiveSkill("#powei_active", {
  interaction = function(self, player)
    local all_choices = {"powei_damage", "powei_prey"}
    local choices = table.simpleClone(all_choices)
    local current = Fk:currentRoom().current
    if current.hp > player.hp or current:isKongcheng() then
      table.remove(choices, 2)
    end
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices , all_choices = all_choices}
  end,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    if self.interaction.data == "powei_damage" then
      return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
        not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data == "powei_damage" then
      return #selected_cards == 1
    else
      return #selected_cards == 0
    end
  end,
})

powei:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function (p)
    return not p:hasSkill(powei.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@powei_wei", 0)
    end
  end
end)

powei:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(powei.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, powei.name)
    player:broadcastSkillInvoke(powei.name, 1)
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      room:setPlayerMark(p, "@@powei_wei", 1)
    end
  end,
})
powei:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(powei.name) then
      if target == player then
        return true
      else
        return target:getMark("@@powei_wei") > 0 and
          (not player:isKongcheng() or (target.hp <= player.hp and not target:isKongcheng()))
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if target == player then
      event:setCostData(self, nil)
      return true
    else
      local room = player.room
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#powei_active",
        prompt = "#powei-invoke::"..target.id,
        cancelable = true,
        no_indicate = false,
      })
      if success and dat then
        event:setCostData(self, {tos = {target}, cards = dat.cards, choice = dat.interaction})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      if table.find(room.alive_players, function(p)
        return p:getMark("@@powei_wei") > 0
      end) then
        room:notifySkillInvoked(player, powei.name)
        player:broadcastSkillInvoke(powei.name, 1)
        local hasLastPlayer = false
        for _, p in ipairs(room:getAlivePlayers()) do
          if p:getMark("@@powei_wei") > (hasLastPlayer and 1 or 0) and not (#room.alive_players < 3 and p:getNextAlive() == player) then
            hasLastPlayer = true
            room:removePlayerMark(p, "@@powei_wei")
            local nextPlayer = p:getNextAlive()
            if nextPlayer == player then
              nextPlayer = player:getNextAlive()
            end
            room:addPlayerMark(nextPlayer, "@@powei_wei")
          else
            hasLastPlayer = false
          end
        end
      else
        room:notifySkillInvoked(player, powei.name)
        player:broadcastSkillInvoke(powei.name, 2)
        room:handleAddLoseSkills(player, "shenzhuo")
        room:updateQuestSkillState(player, powei.name)
        room:invalidateSkill(player, powei.name)
      end
    else
      room:setPlayerMark(player, "powei_debuff-turn", target.id)
      if event:getCostData(self).choice == "powei_damage" then
        room:notifySkillInvoked(player, powei.name, "offensive")
        player:broadcastSkillInvoke(powei.name, 1)
        room:throwCard(event:getCostData(self).cards, powei.name, player, player)
        if not target.dead then
          room:damage{
            from = player,
            to = target,
            damage = 1,
            skillName = powei.name,
          }
        end
      else
        room:notifySkillInvoked(player, powei.name, "control")
        player:broadcastSkillInvoke(powei.name, 1)
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = powei.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, powei.name)
      end
    end
  end,
})
powei:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(powei.name) and target:getMark("@@powei_wei") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(target, "@@powei_wei", 0)
  end,
})
powei:addEffect(fk.EnterDying, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(powei.name) and player.hp < 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, powei.name, "negative")
    player:broadcastSkillInvoke(powei.name, 3)
    room:updateQuestSkillState(player, powei.name, true)
    room:invalidateSkill(player, powei.name)
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = powei.name,
      }
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("@@powei_wei") > 0 then
        room:setPlayerMark(p, "@@powei_wei", 0)
      end
    end
    if not player.dead then
      player:throwAllCards("e", powei.name)
    end
  end,
})
powei:addEffect("atkrange", {
  within_func = function (self, from, to)
    return to:getMark("powei_debuff-turn") == from.id
  end,
})

return powei
