
local lianwu = fk.CreateSkill {
  name = "lianwu",
}

Fk:loadTranslationTable{
  ["lianwu"] = "练武",
  [":lianwu"] = "每回合限一次，当你使用【杀】指定唯一目标后或当你成为【杀】的唯一目标后，使用者每满足一项便可以弃置目标角色的一张牌："..
  "1.装备了武器牌；2.此【杀】受【酒】的效果影响。",

  ["#lianwu-incoke"] = "练武：你可以弃置 %dest %arg张牌",

  ["$lianwu1"] = "爱笑的人，运气都不会差。",
  ["$lianwu2"] = "这是…爱笑的大哥哥？",
}

local spec = {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(lianwu.name) and data.card.trueName == "slash" and
      data:isOnlyTarget(data.to) and not data.to:isNude() and
      player:usedSkillTimes(lianwu.name, Player.HistoryTurn) == 0 then
      if #data.from:getEquipments(Card.SubtypeWeapon) > 0 then
        return true
      end
      if data.use.extra_data and data.use.extra_data.drankBuff then
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    if #data.from:getEquipments(Card.SubtypeWeapon) > 0 then
      n = 1
    end
    if data.use.extra_data and data.use.extra_data.drankBuff then
      n = n + 1
    end
    if room:askToSkillInvoke(data.from, {
      skill_name = lianwu.name,
      prompt = "#lianwu-incoke::"..data.to.id..":"..n,
    }) then
      event:setCostData(self, {tos = {data.to}, choice = n})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    local cards = room:askToChooseCards(data.from, {
      target = data.to,
      min = 1,
      max = n,
      flag = "he",
      skill_name = lianwu.name,
    })
    room:throwCard(cards, lianwu.name, data.to, data.from)
  end,
}

lianwu:addEffect(fk.TargetSpecified, spec)
lianwu:addEffect(fk.TargetConfirmed, spec)

return lianwu
