local xingwu = fk.CreateSkill {
  name = "ty__xingwu",
  derived_piles = "ty__dance",
}

Fk:loadTranslationTable{
  ["ty__xingwu"] = "星舞",
  [":ty__xingwu"] = "弃牌阶段开始时，你可以将一张手牌置于武将牌上，称为“舞”。若你的“舞”达到三张，" ..
  "则你可以移去三张“舞”，弃置一名其他角色装备区里的所有牌，然后对其造成X点伤害（X为移去“舞”的花色数，若为女性角色则为1）。",

  ["ty__dance"] = "舞",
  ["#ty__xingwu-put"] = "星舞：你可以将一张手牌置为“舞”",
  ["#ty__xingwu-remove"] = "星舞：移去三张“舞”并选择一名其他角色，弃置其装备区里的所有牌，对其造成花色数的伤害",

  ["$ty__xingwu1"] = "后方就交给我们吧。",
  ["$ty__xingwu2"] = "休要伤我东吴将士。",
}

xingwu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xingwu.name) and player.phase == Player.Discard and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xingwu.name,
      prompt = "#ty__xingwu-put",
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:addToPile("ty__dance", event:getCostData(self).cards, true, xingwu.name, player)
    if #player:getPile("ty__dance") < 3 or #room:getOtherPlayers(player, false) == 0 then return end

    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 3,
      max_card_num = 3,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|ty__dance",
      skill_name = xingwu.name,
      prompt = "#ty__xingwu-remove",
      extra_data = { expand_pile = "ty__dance" },
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      local n = 1
      to = to[1]
      if not to:isFemale() then
        local suits = {}
        for _, id in ipairs(cards) do
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
        n = #suits
      end
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, xingwu.name, nil, true, player)
      if to.dead then return end
      room:throwCard(to:getCardIds("e"), xingwu.name, to, player)
      if to.dead then return end
      room:damage{
        from = player,
        to = to,
        damage = n,
        skillName = xingwu.name,
      }
    end
  end,
})

return xingwu
