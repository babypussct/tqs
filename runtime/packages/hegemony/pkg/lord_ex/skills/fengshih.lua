local fengshih = fk.CreateSkill {
  name = "ld__fengshih",
}

Fk:loadTranslationTable {
  ["ld__fengshih"] = "锋势",
  [":ld__fengshih"] = "①当你使用牌指定其他角色为唯一目标后，若其手牌数小于你且你与其均有牌，你可以弃置你与其各一张牌，然后此牌造成伤害值+1；②当你成为其他角色使用牌的唯一目标后，若你手牌数小于其且你与其均有牌，其可以令你弃置你与其各一张牌，然后此牌造成伤害值+1。",

  ["#ld__fengshih_back-ask"] = "锋势：是否令%src弃置你与其各一张牌，然后此牌的伤害基数+1",

  ["$ld__fengshih1"] = "雪中送炭？倒不如落井下石！",
  ["$ld__fengshih2"] = "今发兵援羽，敢问是过是功？",
}

fengshih:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(fengshih.name) and #data:getAllTargets() == 1) then return false end
    local to = data.to
    return player:getHandcardNum() > to:getHandcardNum() and not to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    room:askToDiscard(player, {
      target = to,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshih.name,
      cancelable = false,
    })
    if not to:isNude() then
      local cid = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = fengshih.name,
      })
      room:throwCard({ cid }, fengshih.name, to, player)
    end
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

fengshih:addEffect(fk.TargetConfirmed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(fengshih.name) and not player:isNude() and
        #data:getAllTargets() == 1
        and player:getHandcardNum() < data.from:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(data.from,
      { skill_name = fengshih.name, prompt = "#ld__fengshih_back-ask:" .. player.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ld__fengshih")
    room:notifySkillInvoked(player, "ld__fengshih", "negative")
    local cid = room:askToChooseCard(player, {
      target = data.from,
      flag = "he",
      skill_name = fengshih.name,
    })
    room:throwCard({ cid }, fengshih.name, data.from, player)
    if not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = fengshih.name,
        cancelable = false,
      })
    end
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return fengshih
