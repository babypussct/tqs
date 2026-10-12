local fentao = fk.CreateSkill {
  name = "fentao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["fentao"] = "焚涛",
  [":fentao"] = "锁定技，当处于连环状态的其他角色受到火焰伤害时，其选择一项：1.此次传导中的伤害+1；2.弃置一半数量的牌（向上取整），" ..
      "此伤害结算后其横置。",

  ["#fentao-discard"] = "焚涛：请弃置%arg张牌，或点“取消”改为令此次传导中的伤害+1",

  ["$fentao1"] = "以你我长志雄才，席卷九州。",
  ["$fentao2"] = "江东星火，终要席卷天下。",
}

fentao:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(fentao.name) and
        data.damageType == fk.FireDamage and target.chained and target:isAlive() and
        (player:getMark("@xiongzi-noclear") == 0 or player.room:getCurrent() == player)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = fentao.name
    local room = player.room
    local throwNum = math.ceil(#target:getCardIds("he") / 2)

    local optionSeq = player:getMark("@xiongzi-noclear")
    local cards = {}
    if optionSeq ~= "xiongzi_2" and not target:isNude() then
      local prompt = optionSeq ~= "xiongzi_1" and ("#fentao-discard:::" .. throwNum) or nil
      cards = room:askToDiscard(
        target,
        {
          min_num = throwNum,
          max_num = throwNum,
          include_equip = true,
          skill_name = skillName,
          prompt = prompt,
          cancelable = optionSeq ~= "xiongzi_1",
        }
      )
    end

    if optionSeq ~= "xiongzi_1" and #cards == 0 then
      data.damage = data.damage + 1
      if data.chain and data.parent then
        data.parent.extra_data = data.parent.extra_data or {}
        data.parent.extra_data.fentaoAdd = (data.parent.extra_data.fentaoAdd or 0) + 1
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.fentaoChain = target
    end
  end,
})

fentao:addEffect(fk.PreDamage, {
  can_refresh = function(self, event, target, player, data)
    return
        player == player.room.players[1] and
        data.chain and
        data.parent and
        ((data.parent.extra_data or {}).fentaoAdd or 0) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + data.parent.extra_data.fentaoAdd
  end,
})

fentao:addEffect(fk.DamageFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (data.extra_data or {}).fentaoChain == player and not player.chained and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player:setChainState(true)
  end,
})

return fentao
