local wildSkill = fk.CreateSkill{
  name = "wild_skill&",
}
local H = require "packages.hegemony.util"
wildSkill:addEffect("viewas", {
  anim_type = "support",
  prompt = "#wild_skill&",
  pattern = ".",
  interaction = function(self, player)
    if Fk.currentResponsePattern == nil then
      return UI.OptionBox { options = { "wild_vanguard", "companion_peach", "draw2", "draw1" }, direct_send = true }
    end
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    --注意：此函数逻辑仅在view_as返回值为nil才会生效！！！
    if Fk.currentResponsePattern == nil then
      --先驱的目标
      if to_select ~= player and #selected == 0 and
        table.find(Fk:currentRoom().alive_players, function(p)
          return (p.general == "anjiang" or p.deputyGeneral == "anjiang") and p ~= player
        end) then
          return to_select.general == "anjiang" or to_select.deputyGeneral == "anjiang"
      end
    end
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets)
    local choices = { "draw2", "draw1" }
    if player:canUse(Fk:cloneCard("peach", Card.NoSuit, 0, wildSkill.name)) then
      table.insert(choices, "companion_peach")
    end
    if #selected_targets > 0 or table.every(Fk:currentRoom().alive_players, function(p)
      return (p.general ~= "anjiang" and p.deputyGeneral ~= "anjiang") or p == player
    end) then
      table.insert(choices, "wild_vanguard")
    end
    return choices
  end,
  view_as = function(self)
    if Fk.currentResponsePattern then
      return Fk:cloneCard("peach", Card.NoSuit, 0, wildSkill.name)
      --注意：此处仅在客户端可返回卡牌
      --用于响应使用的情况，让req使用cardskill的target_filter
    end
  end,
  on_use = function(self, room, effect, card, params)
    local player = effect.from
    local skillName = wildSkill.name
    H.removeHegMark(player.room, player, "wild", 1)
    local choice = effect.interaction_data
    if choice == "wild_vanguard" then
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        player:drawCards(num, skillName)
      end
      if #effect.tos == 0 or player.dead then return end
      local target = effect.tos[1]
      local choices = { "known_both_main", "known_both_deputy" }
      if target.general ~= "anjiang" then
        table.remove(choices, 1)
      end
      if target.deputyGeneral ~= "anjiang" then
        table.remove(choices)
      end
      if #choices == 0 then return end
      local choice2 = room:askToChoice(player, {
        choices = choices,
        skill_name = skillName,
        prompt = "#known_both-choice::"..target.id,
      })
      H.viewGeneral(player, target, skillName, choice2 == "known_both_main", choice2 == "known_both_deputy")
    elseif choice == "draw2" then
      player:drawCards(2, skillName)
    elseif choice == "draw1" then
      player:drawCards(1, skillName)
    else
      --case: nil（响应使用）、"companion_peach"
      return {---@type UseCardDataSpec
        from = player,
        tos = effect.tos,
        card = Fk:cloneCard("peach", Card.NoSuit, 0, skillName),
      }
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@!!wild") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@!!wild") > 0 and
      player:canUseOrResponseInCurrent(Fk:cloneCard("peach", Card.NoSuit, 0, wildSkill.name))
  end,
})

wildSkill:addEffect(fk.EventPhaseStart, {
  priority = 0.09,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:hasSkill(wildSkill.name)
      and player:getMark("@!!wild") > 0 and player:getHandcardNum() > player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wildSkill.name,
      prompt = "#wild_max-ask",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    H.removeHegMark(room, player, "wild", 1)
    room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 2)
  end,
})

Fk:loadTranslationTable{
  ["wild_skill&"] = "野心家",
  [":wild_skill&"] = "你可弃一枚“野心家”，执行“先驱”、“阴阳鱼”或“珠联璧合”的效果。",
  ["#wild_skill&"] = "你可将“野心家”当一种标记弃置并执行其效果",
  ["wild_vanguard"] = "将手牌摸至4张，观看一张暗置武将牌",
  ["#wild_max-ask"] = "你可弃一枚“野心家”，此回合手牌上限+2",
}

return wildSkill
