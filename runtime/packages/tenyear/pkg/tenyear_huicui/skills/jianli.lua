local jianli = fk.CreateSkill {
  name = "jianli",
}

Fk:loadTranslationTable{
  ["jianli"] = "谏立",
  [":jianli"] = "出牌阶段限两次，你可以交给一名其他角色至多两张牌，然后其可使用一张手牌，若其未因此使用牌造成伤害，你受到其造成的1点伤害。",

  ["#jianli-active"] = "谏立：你可交给一名其他角色至多两张牌，然后其可使用手牌，若其未使用牌造成伤害，你受到伤害",
  ["#jianli-use"] = "谏立：你可使用一张手牌，若你未使用牌造成伤害，%src 受到你造成的伤害",

  ["$jianli1"] = "天下十分而公有其九，此天人之应。",
  ["$jianli2"] = "天下咸知汉祚已尽，公复何疑？",
}

jianli:addEffect("active", {
  times = function(self, player)
    return 2 - player:usedSkillTimes(jianli.name, Player.HistoryPhase)
  end,
  prompt = "#jianli-active",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jianli.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = jianli.name
    local from = effect.from
    local to = effect.tos[1]

    room:obtainCard(to, effect.cards, false, fk.ReasonGive, from, skillName)
    if not to:isAlive() then
      return false
    end

    local use = room:askToUseRealCard(
      to,
      {
        pattern = ".|.|.|hand",
        skill_name = skillName,
        prompt = "#jianli-use:" .. from.id,
      }
    )

    if not (use and use.damageDealt) and from:isAlive() then
      room:damage{
        from = to,
        to = from,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return jianli
