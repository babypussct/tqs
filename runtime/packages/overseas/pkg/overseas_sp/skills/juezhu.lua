local osJuezhu = fk.CreateSkill {
  name = "os__juezhu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__juezhu"] = "决助",
  [":os__juezhu"] = "限定技，出牌阶段，你可废除一个坐骑栏，令一名角色获得〖飞影〗并废除其判定区。其死亡后，你恢复以此法废除的坐骑栏。",

  ["@os__juezhu"] = "决助",
  ["#os__juezhu-active"] = "你可废除一个坐骑栏，令一名角色获得〖飞影〗并废除其判定区",

  ["$os__juezhu1"] = "曹君速上马，洪自断后。",
  ["$os__juezhu2"] = "天下可无洪，不可无君。",
}

osJuezhu:addEffect("active", {
  anim_type = "support",
  prompt = "#os__juezhu-active",
  can_use = function(self, player)
    return
      player:usedSkillTimes(osJuezhu.name, Player.HistoryGame) < 1 and
      (
        #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 or
        #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0
      )
  end,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  interaction_helper = function(self, player, selected_cards, selected_targets)
    local all_choices = { "DefensiveRideSlot", "OffensiveRideSlot" }
    local choices = table.clone(all_choices)
    if #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 then
      table.remove(choices)
    end
    if #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 then
      table.remove(choices, 1)
    end
    return UI.OptionBox{ options = choices, all_options = all_choices }
  end,
  on_use = function(self, room, effect)
    local choice = self.interaction.data
    if not choice then
      return
    end

    local player = effect.from
    local target = effect.tos[1]
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, { slot })
    room:handleAddLoseSkills(target, "feiying")
    room:abortPlayerArea(target, { Player.JudgeSlot })
    room:setPlayerMark(player, "@os__juezhu", target.general)
    room:setPlayerMark(player, "_os__juezhu", { target.id, slot })
  end
})

-- Trigger Skill Effect
osJuezhu:addEffect(fk.Deathed, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("_os__juezhu") ~= 0 and player:getMark("_os__juezhu")[1] == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:resumePlayerArea(player, player:getMark("_os__juezhu")[2])
    room:setPlayerMark(player, "_os__juezhu", 0)
  end
})

return osJuezhu
