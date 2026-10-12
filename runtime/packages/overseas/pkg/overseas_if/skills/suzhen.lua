local suzhen = fk.CreateSkill {
  name = "os__suzhen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["os__suzhen"] = "肃阵",
  [":os__suzhen"] = "锁定技，有角色的受伤状态发生变化后，你获得其一张牌（若为你则改为展示一张牌），若其中有基本牌，你回复1点体力。",

  ["#os__suzhen-obtain"] = "肃阵：获得%dest一张牌，若其中有基本牌，你回复1点体力",
  ["#os__suzhen-show"] = "肃阵：展示一张牌，若其中有基本牌，你回复1点体力",

  ["$os__suzhen1"] = "吾已扫平战事，当卸天下之兵！", -- 其他角色
  ["$os__suzhen2"] = "修兵当贵于精，孰言多多益善？", -- 自己
  ["$os__suzhen3"] = "天下已由吾统，汝等俯首足矣！", -- 回血
}

-- 记录受伤情况
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local suzhen_record = {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(suzhen.name)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.woundedBefore = target:isWounded()
  end
}

-- 受伤后、失去体力后、回复体力后、体力上限变化后执行
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local suzhen_act = {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(suzhen.name) and (data.extra_data or {}).woundedBefore ~= target:isWounded() and not target:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target}, audio_index = player == target and 2 or 1 } )
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target:isNude() then return end
    local card
    if target == player then
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        skill_name = suzhen.name,
        prompt = "#os__suzhen-show",
        include_equip = true,
        cancelable = false,
      })[1]
      room:showCards(card, player, player)
    else
      card = room:askToChooseCards(player, {
        target = target,
        flag = "he",
        min = 1,
        max = 1,
        skill_name = suzhen.name,
        prompt = "#os__suzhen-obtain::" .. target.id,
        cancelable = false,
      })[1]
      room:obtainCard(player, card, true, fk.ReasonPrey, player, suzhen.name)
    end
    if Fk:getCardById(card).type == Card.TypeBasic and player:isAlive() then
      player:broadcastSkillInvoke(suzhen.name, 3)
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = suzhen.name,
      }
    end
  end,
}

suzhen:addEffect(fk.DamageInflicted, suzhen_record)
suzhen:addEffect(fk.PreHpLost, suzhen_record)
suzhen:addEffect(fk.PreHpRecover, suzhen_record)
suzhen:addEffect(fk.BeforeMaxHpChanged, suzhen_record)

suzhen:addEffect(fk.Damaged, suzhen_act)
suzhen:addEffect(fk.HpLost, suzhen_act)
suzhen:addEffect(fk.HpRecover, suzhen_act)
suzhen:addEffect(fk.MaxHpChanged, suzhen_act)

return suzhen
