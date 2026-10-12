local liwu = fk.CreateSkill {
  name = "os__liwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__liwu"] = "励伍",
  [":os__liwu"] = "锁定技，有角色的受伤状态发生变化后，你摸一张牌，若其中有基本牌，你下一次造成伤害+1。",

  ["@os__liwu"] = "励伍",

  ["$os__liwu1"] = "终有一日，我必尽得江东！", -- 其他角色
  ["$os__liwu2"] = "兵马在我之手，何患玉玺有失！", -- 自己变为受伤
  ["$os__liwu3"] = "众将与我同心讨贼，来日皆可据土封疆！", -- 自己变为未受伤
  ["$os__liwu4"] = "转战大江南北，扬我孙氏之名！", -- 加伤
}

-- 记录受伤情况
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local liwu_record = {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(liwu.name)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.woundedBefore = target:isWounded()
  end
}

-- 受伤后、失去体力后、回复体力后、体力上限变化后执行
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local liwu_act = {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(liwu.name) and (data.extra_data or {}).woundedBefore ~= target:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target}, audio_index = target == player and (player:isWounded() and 2 or 3) or 1 } )
    return true
  end,
  on_use = function (self, event, target, player, data)
    local card = player:drawCards(1, liwu.name)[1]
    if Fk:getCardById(card).type == Card.TypeBasic and player:isAlive() then
      player.room:addPlayerMark(player, "@os__liwu")
    end
  end,
}

liwu:addEffect(fk.DamageInflicted, liwu_record)
liwu:addEffect(fk.PreHpLost, liwu_record)
liwu:addEffect(fk.PreHpRecover, liwu_record)
liwu:addEffect(fk.BeforeMaxHpChanged, liwu_record)

liwu:addEffect(fk.Damaged, liwu_act)
liwu:addEffect(fk.HpLost, liwu_act)
liwu:addEffect(fk.HpRecover, liwu_act)
liwu:addEffect(fk.MaxHpChanged, liwu_act)

liwu:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  audio_index = 4,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(liwu.name) and
      player:getMark("@os__liwu") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(player:getMark("@os__liwu"))
    player.room:setPlayerMark(player, "@os__liwu", 0)
  end
})

return liwu
