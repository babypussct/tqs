local luanwu = fk.CreateSkill {
  name = "luanwu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["luanwu"] = "乱武",
  [":luanwu"] = "限定技，出牌阶段，你可选择所有其他角色，这些角色各需对包括距离最小的另一名角色在内的角色使用【杀】，否则失去1点体力。",

  ["#luanwu"] = "乱武：令所有其他角色选择使用【杀】或失去体力！",
  ["#luanwu-use"] = "乱武：你需要对距离最近的一名角色使用一张【杀】，否则失去1点体力",

  ["$luanwu1"] = "哼哼哼……坐山观虎斗！",
  ["$luanwu2"] = "哭喊吧，哀求吧，挣扎吧，然后，死吧！",
}

luanwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#luanwu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(luanwu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_cost = function(self, player, data)
    return { tos = player.room:getOtherPlayers(player) }
  end,
  on_use = function(self, room, effect)
    for _, target in ipairs(effect.tos) do
      if not target.dead then
        local other_players = table.filter(room:getOtherPlayers(target, false), function(p)
          return not p:isRemoved()
        end)
        local luanwu_targets = table.filter(other_players, function(p2)
          return table.every(other_players, function(p1)
            return target:distanceTo(p1) >= target:distanceTo(p2)
          end)
        end)
        local use = room:askToUseCard(target, {
          pattern = "slash",
          prompt = "#luanwu-use",
          cancelable = true,
          extra_data = {
            exclusive_targets = table.map(luanwu_targets, Util.IdMapper),
            bypass_times = true,
          },
          skill_name = luanwu.name,
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        else
          room:loseHp(target, 1, luanwu.name)
        end
      end
    end
  end,
})

luanwu:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    return { {}, {} }, ai:getBenefitOfEvents(function(logic)
      for _, p in ipairs(ai.room:getOtherPlayers(ai.player)) do
        logic:loseHp(p, 1, self.skill_name)
      end
    end)
  end,
})

return luanwu
