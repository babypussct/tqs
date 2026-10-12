local ronghuo = fk.CreateSkill {
  name = "ronghuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ronghuo"] = "融火",
  [":ronghuo"] = "锁定技，有角色受到火焰伤害后，你下一次使用【火杀】或【火攻】额外指定1个目标，"..
    "你使用【火杀】或【火攻】造成的伤害+X（X为全场势力数）。",

  ["@@ronghuo"] = "融火",
  ["#ronghuo-choose"] = "融火：你可以为此%arg额外指定一个目标",

  ["$ronghuo1"] = "火莲绽江矶，炎映三千弱水。",
  ["$ronghuo2"] = "奇志吞樯橹，潮平百万寇贼。",
}

ronghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ronghuo.name) and data.card and
      table.contains({"fire_attack", "fire__slash"}, data.card.name) and
      player.room.logic:damageByCardEffect()
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data:changeDamage(#kingdoms)
  end,
})

ronghuo:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.damageType == fk.FireDamage and player:hasSkill(ronghuo.name) and player:getMark("@@ronghuo") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ronghuo", 1)
  end,
})

ronghuo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and table.contains({"fire_attack", "fire__slash"}, data.card.name) and
      player:hasSkill(ronghuo.name) and player:getMark("@@ronghuo") > 0 and target==player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ronghuo", 0)
    local tos = data:getExtraTargets()
    if #tos == 0 then return end
    tos = player.room:askToChoosePlayers(player, {
      targets = tos,
      min_num = 1,
      max_num = 1,
      prompt = "#ronghuo-choose:::"..data.card:toLogString(),
      skill_name = ronghuo.name,
    })
    if #tos > 0 then
      data:addTarget(tos)
    end
  end,
})

ronghuo:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@@ronghuo", 0)
end)

return ronghuo
