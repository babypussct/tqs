local yiyong = fk.CreateSkill {
  name = "yiyongw",
}

Fk:loadTranslationTable{
  ["yiyongw"] = "异勇",
  [":yiyongw"] = "当你受到其他角色使用【杀】造成的伤害后，若你的装备区里有武器牌，你可以获得此【杀】，然后将此【杀】当普【杀】对其使用"..
  "（若其装备区里没有武器牌，此【杀】对其造成的伤害+1）。",

  ["#yiyongw-invoke"] = "异勇：你可以获得此%arg，将之当【杀】对 %dest 使用",

  ["$yiyongw1"] = "这么着急回营？哼！那我就送你一程！",
  ["$yiyongw2"] = "你的兵器，本大爷还给你！哈哈哈哈！",
}

yiyong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yiyong.name) and data.card and data.card.trueName == "slash" and
      data.from and data.from ~= player and not data.from.dead and #player:getEquipments(Card.SubtypeWeapon) > 0 and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yiyong.name,
      prompt = "#yiyongw-invoke::"..data.from.id..":"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, data.card, true, fk.ReasonPrey, player, yiyong.name)
    if player.dead or data.from.dead then return end
    local subcards = Card:getIdList(data.card)
    if table.every(subcards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end) then
      local card = Fk:cloneCard("slash")
      card:addSubcards(subcards)
      card.skillName = yiyong.name
      if player:canUseTo(card, data.from, {bypass_distances = true, bypass_times = true}) then
        local use = {
          from = player,
          tos = { data.from },
          card = card,
          extraUse = true,
        }
        if #data.from:getEquipments(Card.SubtypeWeapon) == 0 then
          use.extra_data = use.extra_data or {}
          use.extra_data.yiyongw_victim = data.from
        end
        room:useCard(use)
      end
    end
  end,
})
yiyong:addEffect(fk.DamageInflicted, {
  can_refresh = function (self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data
        return use.extra_data and use.extra_data.yiyongw_victim == player
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return yiyong
