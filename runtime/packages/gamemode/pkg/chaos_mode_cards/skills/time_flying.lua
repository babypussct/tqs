local skill = fk.CreateSkill {
  name = "time_flying_skill",
}

skill:addEffect("cardskill", {
  prompt = "#time_flying_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to.dead or from.dead then return end
    local num, num2 = from.hp, to.hp
    local min = math.max(1 - num, num2 - to.maxHp)
    local max = math.min(from.maxHp - num, num2 - 1)
    num = min == max and min or math.random(min, max)
    if num > 0 then
      room:recover{
        who = from,
        num = num,
        recoverBy = from,
        skillName = skill.name,
      }
      if not to.dead then
        room:loseHp(to, num, skill.name)
      end
    elseif num < 0 then
      num = -num
      room:loseHp(from, num, skill.name)
      if not to.dead then
        room:recover{
          who = to,
          num = num,
          recoverBy = from,
          skillName = skill.name,
        }
      end
    end
  end,
})

return skill
