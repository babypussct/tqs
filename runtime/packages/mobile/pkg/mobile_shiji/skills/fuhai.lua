local fuhai = fk.CreateSkill {
  name = "fuhai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuhai"] = "覆海",
  [":fuhai"] = "锁定技，当你使用牌指定拥有“平定”标记的角色为目标后，其不能响应此牌，且你摸一张牌（每回合限摸两张）；当拥有“平定”标记的角色死亡时，"..
  "你增加X点体力上限并摸X张牌（X为其“平定”标记数）。",

  ["$fuhai1"] = "翻江复蹈海，六合定乾坤！",
  ["$fuhai2"] = "力攻平江东，威名扬天下！",
}

fuhai:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuhai.name) and data.to:getMark("@yingba_pingding") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    table.insert(data.use.disresponsiveList, data.to)
    if player:usedEffectTimes(fuhai.name) < 3 then
      player:drawCards(1, fuhai.name)
    end
  end,
})
fuhai:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuhai.name) and target:getMark("@yingba_pingding") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("@yingba_pingding")
    room:changeMaxHp(player, n)
    if not player.dead then
      player:drawCards(n, fuhai.name)
    end
  end,
})

return fuhai
