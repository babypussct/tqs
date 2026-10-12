local osFujian = fk.CreateSkill {
  name = "os__fujian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__fujian"] = "负剑",
  [":os__fujian"] = "锁定技，①游戏开始时或准备阶段，若你的装备区里没有武器牌，则你从牌堆中随机获得一张武器牌并将其置入装备区。" ..
  "②当你于回合外失去武器牌后，你失去1点体力。",

  ["$os__fujian1"] = "得此宝剑，如虎添翼！",
  ["$os__fujian2"] = "丞相至宝，汝岂配用之？啊！……",
}

local osFujianWeaponOnUse = function(self, event, target, player, data)
  ---@type string
  local skillName = osFujian.name
  local room = player.room
  room:notifySkillInvoked(player, skillName, "drawcard")
  player:broadcastSkillInvoke(skillName, 1)

  local id = room:getCardsFromPileByRule(".|.|.|.|.|weapon")
  if #id > 0 then
    room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)
    if player.dead or not table.contains(player:getCardIds("h"), id[1]) then return end
    if player:canMoveCardIntoEquip(id[1], false) then
      room:moveCardIntoEquip(player, id[1], osFujian.name, false, player)
    end
  end
end

osFujian:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osFujian.name) and #player:getEquipments(Card.SubtypeWeapon) == 0
  end,
  on_use = osFujianWeaponOnUse,
})

osFujian:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return
      player == target and
      target.phase == Player.Start and
      player:hasSkill(osFujian.name) and
      not player:getEquipment(Card.SubtypeWeapon)
  end,
  on_use = osFujianWeaponOnUse,
})

osFujian:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osFujian.name) or player.phase ~= Player.NotActive then
      return false
    end

    for _, move in ipairs(data) do
      if
        move.from == player and
        (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip))
      then
        for _, info in ipairs(move.moveInfo) do
          if
            Fk:getCardById(info.cardId).sub_type == Card.SubtypeWeapon and
            (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
          then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osFujian.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "negative")
    player:broadcastSkillInvoke(skillName, 2)
    room:loseHp(player, 1, skillName)
  end,
})

return osFujian
