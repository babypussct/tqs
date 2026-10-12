
local zhubo = fk.CreateSkill {
  name = "zhubo",
  dynamic_desc = function (self, player, lang)
    if player:getMark("qijue") == 1 then
      return "zhubo_inner1"
    elseif player:getMark("qijue") == 2 then
      return "zhubo_inner2"
    end
  end,
}

Fk:loadTranslationTable{
  ["zhubo"] = "逐波",
  [":zhubo"] = "每回合限一次，一名角色于其出牌阶段外造成伤害时，你可以失去1点体力并选择一项：1.你与其各摸两张牌；2.此伤害+1。",

  [":zhubo_inner1"] = "每回合限一次，一名角色于其出牌阶段外受到伤害时，你可以失去1点体力并选择一项：1.你与其各摸两张牌；2.此伤害+1。",
  [":zhubo_inner2"] = "每回合限一次，你于回合外造成或受到伤害时，你可以选择一项：1.你与其各摸两张牌；2.此伤害+1。",

  ["#zhubo-invoke"] = "逐波：你可以失去1点体力并选择一项",
  ["#zhubo_update-invoke"] = "逐波：你可以选择一项",
  ["zhubo_draw"] = "你与%dest各摸两张牌",
  ["zhubo_damage"] = "此伤害+1",

  ["$zhubo1"] = "",
  ["$zhubo2"] = "",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      skill_name = zhubo.name,
      prompt = player:getMark("qijue") == 2 and "#zhubo_update-invoke" or "#zhubo-invoke",
      choices = { "zhubo_draw::"..target.id, "zhubo_damage" },
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("qijue") < 2 then
      room:loseHp(player, 1, zhubo.name, player)
    end
    local choice = event:getCostData(self).choice
    if choice == "zhubo_damage" then
      data:changeDamage(1)
    else
      if not player.dead then
        player:drawCards(2, zhubo.name)
      end
      if not target.dead then
        target:drawCards(2, zhubo.name)
      end
    end
  end,
}

zhubo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhubo.name) and
      target and player:usedSkillTimes(zhubo.name, Player.HistoryTurn) == 0 then
      if player:getMark("qijue") == 0 then
        return target.phase ~= Player.Play and player.hp > 0
      elseif player:getMark("qijue") == 2 then
        return target == player and player.room:getCurrent() ~= player
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

zhubo:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhubo.name) and
      player:usedSkillTimes(zhubo.name, Player.HistoryTurn) == 0 then
      if player:getMark("qijue") == 1 then
        return target.phase ~= Player.Play and player.hp > 0
      elseif player:getMark("qijue") == 2 then
        return target == player and player.room:getCurrent() ~= player
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return zhubo
