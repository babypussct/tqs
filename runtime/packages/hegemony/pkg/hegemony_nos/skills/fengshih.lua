
local fengshih = fk.CreateSkill {
  name = "nos_heg__fengshih",
}

Fk:loadTranslationTable {
  ["nos_heg__fengshih"] = "锋势",
  [":nos_heg__fengshih"] = "当你使用牌指定唯一目标后，若你与其均有牌且其手牌数小于你，你可以弃置你与其各一张牌，令此牌伤害+1；"..
  "当你成为其他角色使用牌的唯一目标后，若你与其均有牌且你手牌数小于其，其可以令你弃置你与其各一张牌，令此牌伤害+1。",

  ["#nos_heg__fengshih-invoke"] = "锋势：是否令 %src 弃置你与其各一张牌，此牌伤害+1？",
  ["#nos_heg__fengshih-discard"] = "锋势：弃置 %dest 一张牌",

  ["$nos_heg__fengshih1"] = "雪中送炭？倒不如落井下石！",
  ["$nos_heg__fengshih2"] = "今发兵援羽，敢问是过是功？",
}

fengshih:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengshih.name) and
      data:isOnlyTarget(data.to) and
      player:getHandcardNum() > data.to:getHandcardNum() and not data.to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(data.from, {
      skill_name = fengshih.name,
      prompt = "#nos_heg__fengshih-invoke:" .. player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshih.name,
      prompt = "#nos_heg__fengshih-discard::"..player.id,
      cancelable = false,
    })
    if not data.to:isNude() and not player.dead then
      local id = room:askToChooseCard(player, {
        target = data.to,
        flag = "he",
        skill_name = fengshih.name,
        prompt = "#nos_heg__fengshih-discard::"..data.to.id,
      })
      room:throwCard(id, fengshih.name, data.to, player)
    end
    data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
  end,
})

fengshih:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(fengshih.name) and
      data:isOnlyTarget(player) and
      player:getHandcardNum() < data.from:getHandcardNum() and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(data.from, {
      skill_name = fengshih.name,
      prompt = "#nos_heg__fengshih-invoke:" .. player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshih.name,
      prompt = "#nos_heg__fengshih-discard::"..player.id,
      cancelable = false,
    })
    if not data.from:isNude() and not player.dead then
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = fengshih.name,
        prompt = "#nos_heg__fengshih-discard::"..data.from.id,
      })
      room:throwCard(id, fengshih.name, data.from, player)
    end
    data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
  end,
})

return fengshih
