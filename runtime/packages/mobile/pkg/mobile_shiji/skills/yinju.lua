local yinju = fk.CreateSkill {
  name = "mobile__yinju",
}

Fk:loadTranslationTable{
  ["mobile__yinju"] = "引裾",
  [":mobile__yinju"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.其下个回合的准备阶段，" ..
  "跳过其本回合的出牌阶段和弃牌阶段；2.对你使用一张无距离限制的【杀】。",

  ["#mobile__yinju"] = "引裾：令一名其他角色选择：对你使用【杀】，或跳过其下回合出牌阶段和弃牌阶段",
  ["@@mobile__yinju"] = "引裾",
  ["#mobile__yinju-slash"] = "引裾：你需对 %src 使用【杀】，否则跳过你下回合出牌阶段和弃牌阶段",

  ["$mobile__yinju1"] = "伐吴者，兴师劳民，徒而无功，万望陛下三思！",
  ["$mobile__yinju2"] = "今当屯田罢兵，徐图吴蜀，安能急躁冒进乎？",
}

yinju:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__yinju",
  can_use = function(self, player)
    return player:usedSkillTimes(yinju.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local use = room:askToUseCard(target, {
      skill_name = yinju.name,
      pattern = "slash",
      prompt = "#mobile__yinju-slash:"..player.id,
      extra_data = {
        exclusive_targets = {player.id},
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      room:setPlayerMark(target, "@@mobile__yinju", 1)
    end
  end,
})
yinju:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("@@mobile__yinju") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mobile__yinju", 0)
    player:skip(Player.Play)
    player:skip(Player.Discard)
  end,
})

return yinju
