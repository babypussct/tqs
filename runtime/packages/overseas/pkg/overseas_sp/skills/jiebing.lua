local jiebing = fk.CreateSkill {
  name = "os__jiebing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["os__jiebing"] = "借兵",
  [":os__jiebing"] = "锁定技，当你受到伤害后，须选择除伤害来源以外的一名其他角色，" ..
      "观看并获得其一张牌并展示之，然后你可以使用此牌。",

  ["#os__jiebing-choose"] = "借兵：选择一名角色，获得其一张牌",
  ["#os__jiebing-card"] = "借兵：获得%dest一张牌",
  ["#os__jiebing-use"] = "借兵：你可以使用%arg",

  ["$os__jiebing1"] = "一州之士皆蒙其耻，岂独阜之忧责！",
  ["$os__jiebing2"] = "战事紧急，怎可手无兵士！",
}

---@type TrigSkelSpec<DamageTrigFunc|MoveCardsFunc>
local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude() and (event == fk.AfterCardsMove or p ~= data.from)
    end)
    local tos = #targets == 1 and targets or room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jiebing.name,
      prompt = "#os__jiebing-choose",
      cancelable = false,
    })
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card_data = {}
    if not to:isKongcheng() then
        table.insert(card_data, { "$Hand", to.player_cards[Player.Hand] })
      end
      if #to.player_cards[Player.Equip] > 0 then
        table.insert(card_data, { "$Equip", to.player_cards[Player.Equip] })
      end
    if #card_data == 0 then return end
    local id = room:askToChooseCard(player, {
      target = to,
      flag = {card_data = card_data},
      skill_name = jiebing.name,
      prompt = "#os__jiebing-card::" .. to.id,
    })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, jiebing.name)
    if not table.contains(player:getCardIds("h"), id) or player.dead then return end
    player:showCards(id)
    if not table.contains(player:getCardIds("h"), id) or player.dead then return end
    local card = Fk:getCardById(id)
    if player:canUse(card) then
      room:askToUseRealCard(player, {
        pattern = { id },
        skill_name = jiebing.name,
        prompt = "#os__jiebing-use:::" .. card:toLogString(),
        cancelable = true,
      })
    end
  end,
}

jiebing:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiebing.name) and
        table.find(player.room:getOtherPlayers(player, false), function(p)
          return not p:isNude() and p ~= data.from
        end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
--[[
jiebing:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(jiebing.name) then return end
    local invoke = false
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason ~= fk.ReasonUse and
          (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        invoke = true
        break
      end
    end
    return invoke and table.find(player.room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})]]

return jiebing
