local qiaowu = fk.CreateSkill{
  name = "qiaowu",
  max_branches_use_time = {
    ["slash"] = {
      [Player.HistoryTurn] = 1
    },
    ["jink"] = {
      [Player.HistoryTurn] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["qiaowu"] = "俏舞",
  [":qiaowu"] = "每回合各限一次，当你使用的【杀】或【闪】结算完毕后，你可令所有处于【酒】状态的角色使用一张【杀】，"..
    "若其未使用则其摸一张牌。",

  ["#qiaowu-invoke"] = "俏舞：令所有处于【酒】状态的角色各可使用一张【杀】或摸一张牌",
  ["#qiaowu-use"] = "俏舞：你可使用一张【杀】，不使用则摸一张牌",

  ["$qiaowu1"] = "",
  ["$qiaowu2"] = "",
}

qiaowu:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player == target and table.contains({ "slash", "jink" }, data.card.trueName) and
      player:hasSkill(qiaowu.name) and qiaowu:withinBranchTimesLimit(player, data.card.trueName, Player.HistoryTurn) and
      table.find(player.room.alive_players, function(p)
        return p.drank > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, { skill_name = qiaowu.name, prompt = "#qiaowu-invoke" }) then
      event:setCostData(self, { tos = table.filter(room:getAlivePlayers(), function(p)
        return p.drank > 0
      end), history_branch = data.card.trueName })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = qiaowu.name
    local room = player.room
    for _, to in ipairs(event:getCostData(self).tos) do
      if not to.dead then
        local use = room:askToUseCard(to, {
          skill_name = skillName,
          pattern = "slash",
          prompt = "#qiaowu-use",
          cancelable = true,
          extra_data = {
            bypass_times = true,
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        elseif not to.dead then
          to:drawCards(1, skillName)
        end
      end
    end
  end,
})

return qiaowu
