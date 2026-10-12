local hannan = fk.CreateSkill{
  name = "hannan",
}

Fk:loadTranslationTable{
  ["hannan"] = "扞难",
  [":hannan"] = "出牌阶段限一次，你可以与一名其他角色拼点，拼点赢的角色对拼点没赢的角色造成1点伤害。",

  ["#hannan"] = "扞难：与一名角色拼点，赢的角色对没赢的角色造成1点伤害！",

  ["$hannan1"] = "贼寇虽勇，阜亦戮力以捍！",
  ["$hannan2"] = "纵使信布之勇，亦非无策可当！",
}

hannan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#hannan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(hannan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, hannan.name)
    local from, to
    if pindian.results[target].winner == player then
      from, to = player, target
    elseif pindian.results[target].winner == target then
      from, to = target, player
    end
    if to and not to.dead then
      room:damage{
        from = from,
        to = to,
        damage = 1,
        skillName = hannan.name,
      }
    end
  end,
})

return hannan
