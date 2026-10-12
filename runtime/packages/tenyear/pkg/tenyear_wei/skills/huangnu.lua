local huangnu = fk.CreateSkill {
  name = "huangnu",
}

Fk:loadTranslationTable{
  ["huangnu"] = "煌怒",
  [":huangnu"] = "出牌阶段或受到伤害后，你可以选择一项："..
  "1.选择一名角色令其随机弃置一张你指定类别的牌；2.视为使用一张【杀】；3.令一名角色本回合下次使用的牌无效。"..
  "执行后随机恢复X个装备栏（X为此技能本回合发动次数），若恢复数不足对应数量则此技能本回合失效。",

  ["#huangnu-invoke"] = "煌怒：你可以选择一项发动",
  ["huangnu_discard"] = "令一名角色随机弃置一张你指定类别的牌",
  ["huangnu_slash"] = "视为使用【杀】",
  ["huangnu_negate"] = "令一名角色本回合下次使用牌无效",
  ["#huangnu-discard"] = "煌怒：令一名角色随机弃置一张你指定类别的牌",
  ["#huangnu-slash"] = "煌怒：视为使用【杀】",
  ["#huangnu-negate"] = "煌怒：令一名角色本回合下次使用牌无效",
  ["@@huangnu-turn"] = "煌怒",
  ["huangnu_active"] = "煌怒",

  ["$huangnu1"] = "豺狼叩关，我辈岂有退让之理！",
  ["$huangnu2"] = "我大汉山河，不容沦丧半分！",
}

huangnu:addAuxActiveSkill("huangnu_active", {
  interaction = UI.OptionBox { options = { "basic", "trick", "equip" }, direct_send = true },
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isNude()
  end,
})

huangnu:addEffect("active", {
  anim_type = "support",
  prompt = "#huangnu-invoke",
  interaction = function(self, player)
    local all_choices = {
      "huangnu_discard",
      "huangnu_slash",
      "huangnu_negate"
    }
    local choices = table.simpleClone(all_choices)
    local slash = Fk:cloneCard("slash")
    slash.skillName = huangnu.name
    if #slash:getAvailableTargets(player, { bypass_times = true }) == 0 then
      table.remove(choices, 2)
    end
    if table.every(Fk:currentRoom().alive_players, function(p)
      return p:isNude()
    end) then
      table.remove(choices, 1)
    end
    return UI.OptionBox {
      options = choices,
      all_options = all_choices,
      direct_send = true
    }
  end,
  min_card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local skillName = huangnu.name
    local player = effect.from
    local choice = effect.interaction_data
    local x = player:usedSkillTimes(skillName)
    if choice == "huangnu_discard" then
      local to = table.find(room.alive_players, function(p)
        return not p:isNude()
      end)
      if to then
        choice = "basic"
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "huangnu_active",
          prompt = "#huangnu-discard",
          cancelable = false,
          skip = true,
        })
        if success and dat then
          choice = dat.interaction
          to = dat.targets[1]
        end
        local cards = table.filter(to:getCardIds("he"), function(id)
          local c = Fk:getCardById(id)
          return c:getTypeString() == choice and not to:prohibitDiscard(c)
        end)
        if #cards > 0 then
          room:throwCard(room:tableRandomPick(cards), skillName, to, to)
        end
      end
    elseif choice == "huangnu_slash" then
      room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = skillName,
        prompt = "#huangnu-slash",
        cancelable = false,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
      if player.dead then return end
    elseif choice == "huangnu_negate" then
      room:setPlayerMark(room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = skillName,
        prompt = "#huangnu-negate",
        cancelable = false,
      })[1], "@@huangnu-turn", 1)
    end
    local sealedSlots = table.filter(player.sealedSlots, function(slot)
      return slot ~= Player.JudgeSlot
    end)
    if #sealedSlots < x then
      room:resumePlayerArea(player, sealedSlots)
      room:invalidateSkill(player, skillName, "-turn")
    else
      local slotsToResume = room:tableRandomPick(sealedSlots, x)
      room:resumePlayerArea(player, slotsToResume)
    end
  end,
})

huangnu:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@huangnu-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@huangnu-turn", 0)
    --data.toCard = nil
    --data:removeAllTargets()
    data:setNullified()
  end,
})

huangnu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local skillName = huangnu.name
    local room = player.room
    local all_choices = {
      "huangnu_discard",
      "huangnu_slash",
      "huangnu_negate",
      "Cancel"
    }
    local choices = table.simpleClone(all_choices)
    local slash = Fk:cloneCard("slash")
    slash.skillName = skillName
    if #slash:getAvailableTargets(player, { bypass_times = true }) == 0 then
      table.remove(choices, 2)
    end
    if table.every(room.alive_players, function(p)
      return p:isNude()
    end) then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = all_choices,
      skill_name = skillName,
      prompt = "#huangnu-invoke"
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {
        from = player,
        cards = {},
        tos = {},
        interaction_data = choice
      })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@diagnostic disable-next-line assign-type-mismatch
    local skill = Fk.skills[huangnu.name] ---@type ActiveSkill
    skill:onUse(player.room, event:getCostData(self))
  end,
})

return huangnu
