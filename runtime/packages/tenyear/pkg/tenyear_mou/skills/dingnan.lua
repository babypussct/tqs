local dingnan = fk.CreateSkill {
  name = "dingnan",
}

Fk:loadTranslationTable{
  ["dingnan"] = "定南",
  [":dingnan"] = "出牌阶段限一次，你可以令任意名角色依次打出一张【杀】，否则其受到1点伤害。",

  ["#dingnan"] = "定南：令任意名角色依次打出一张【杀】，否则其受到1点伤害",
  ["#dingnan-response"] = "定南：请打出一张【杀】，否则受到1点伤害",

  ["$dingnan1"] = "七擒七纵南疆定，三顾三分天下平。",
  ["$dingnan2"] = "自此南中归汉，汉亦不负南中。",
}

dingnan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#dingnan",
  card_num = 0,
  min_target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(dingnan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
  on_use = function (self, room, effect)
    local tos = effect.tos
    room:sortByAction(tos)
    table.forEach(tos, function(p)
      if p:isAlive() then
        local response = room:askToResponse(
          p,
          {
            pattern = "slash",
            skill_name = dingnan.name,
            prompt = "#dingnan-response",
          }
        )

        if response then
          room:responseCard(response)
        else
          room:damage{
            to = p,
            damage = 1,
            skillName = dingnan.name,
          }
        end
      end
    end)
  end,
})

return dingnan
