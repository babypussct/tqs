local xiawang = fk.CreateSkill {
  name = "os__xiawang",
}

Fk:loadTranslationTable{
  ["os__xiawang"] = "侠望",
  [":os__xiawang"] = "当与你距离不大于1的角色受到黑色牌造成的伤害后，你可以对伤害来源使用【杀】，若此【杀】造成伤害，则结束当前阶段。",

  ["#os__xiawang-use"] = "你可以对 %dest 使用【杀】，若造成伤害则结束当前阶段",

  ["$os__xiawang1"] = "天下兴亡，侠客当为之己任。",
  ["$os__xiawang2"] = "隐居江湖之远，敢争天下之先！",
}

xiawang:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiawang.name) and target:distanceTo(player) < 2 and
      data.card and data.card.color == Card.Black and target:isAlive() and
      data.from and data.from:isAlive() and
      player:canUseTo(Fk:cloneCard("slash"), data.from, {bypass_distances = true, bypass_times = true})
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(player, {
      skill_name = xiawang.name,
      prompt = "#os__xiawang-use::" .. data.from.id,
      pattern = "slash",
      extra_data = {
        exclusive_targets = {data.from.id},
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self)
    room:useCard(use)
    if use.damageDealt then
      room.logic:getCurrentEvent():addCleaner(function()
        room.current:endCurrentPhase()
      end)
    end
  end,
})

return xiawang
