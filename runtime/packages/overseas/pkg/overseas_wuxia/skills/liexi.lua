local liexi = fk.CreateSkill {
  name = "os__liexi"
}

Fk:loadTranslationTable{
  ["os__liexi"] = "烈袭",
  [":os__liexi"] = "准备阶段，你可以弃置任意张牌并选择一名其他角色，若你弃置的牌数大于其体力值，" ..
  "则你对其造成1点伤害；否则其对你造成1点伤害；若你弃置的牌中包含武器牌，你对其造成1点伤害。",

  ["#os__liexi-invoke"] = "烈袭：弃置任意张牌并选择一名其他角色，弃牌数大于其体力或包含武器牌则对其造成伤害",

  ["$os__liexi1"] = "短兵强击，贯汝心扉！",
  ["$os__liexi2"] = "性刚情烈，目不容奸！"
}

liexi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liexi.name) and player.phase == Player.Start and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = liexi.name
    local room = player.room
    local to, cids = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = #player:getCardIds("he"),
      targets = room:getOtherPlayers(player, false),
      include_equip = true,
      skill_name = skillName,
      cancelable = true,
      skip = true,
      prompt = "#os__liexi-invoke",
      will_throw = true,
    })
    if #to > 0 and #cids > 0 then
      event:setCostData(self, {tos = to, cards = cids})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = liexi.name
    local room = player.room
    local cards = event:getCostData(self).cards
    local to = event:getCostData(self).tos[1]
    local yes = table.find(cards, function(id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon
    end)
    room:throwCard(cards, skillName, player, player)
    if to.dead then return end
    if #cards > to.hp then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skillName,
      }
    elseif not player.dead then
      room:damage{
        from = to,
        to = player,
        damage = 1,
        skillName = skillName,
      }
    end
    if yes and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return liexi
