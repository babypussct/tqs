
local wance = fk.CreateSkill {
  name = "wance",
}

Fk:loadTranslationTable{
  ["wance"] = "完策",
  [":wance"] = "出牌阶段限一次，你可以指定一名角色并声明一张指定唯一目标的普通锦囊牌，然后其依次将X张手牌当此牌使用"..
  "（X为游戏轮数且至多为3）。其以此法指定目标时，你可以弃置一张牌并更改目标。",

  ["#wance"] = "完策：指定一名角色并声明一张普通锦囊牌，其依次将%arg张手牌当此牌使用",
  ["#wance-use"] = "完策：请将一张手牌当【%arg】使用（还需执行%arg2次）",
  ["#wance-choose"] = "完策：你可以弃置一张牌，更改%arg的目标",

  ["$wance1"] = "你，看得清这局势吗？",
  ["$wance2"] = "你越是挣脱，便陷得越深。",
}

wance:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#wance:::"..math.min(Fk:currentRoom():getBanner("RoundCount"), 3)
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(wance.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local names = table.filter(Fk:getAllCardNames("t"), function(name)
      return not Fk:cloneCard(name).multiple_targets and not Fk:cloneCard(name).is_passive
    end)
    return UI.CardNameBox { choices = names }
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local total = math.min(room:getBanner("RoundCount"), 3)
    for i = 1, total do
      local use = room:askToUseVirtualCard(target, {
        name = self.interaction.data,
        skill_name = wance.name,
        prompt = "#wance-use:::"..self.interaction.data..":"..(total - i + 1),
        cancelable = false,
        card_filter = {
          n = 1,
          cards = target:getHandlyIds(),
        }
      })
      if not use or target.dead then
        return
      end
    end
  end,
})

wance:addEffect(fk.TargetSpecifying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player and table.contains(data.card.skillNames, wance.name) and
      data.firstTarget and not player:isNude() and #data:getExtraTargets() > 0 then
      local skill_effect = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
      return skill_effect and skill_effect.data.who == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = data:getExtraTargets(),
      skill_name = wance.name,
      prompt = "#wance-choose:::"..data.card:toLogString(),
      cancelable = true,
      will_throw = true,
    })
    if #to > 0 and #card > 0 then
      room:throwCard(card, wance.name, player, player)
      if data:cancelCurrentTarget() then
        data:addTarget(to[1])
      end
    end
  end,
})

return wance
