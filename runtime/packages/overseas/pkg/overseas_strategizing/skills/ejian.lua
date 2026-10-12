local ejian = fk.CreateSkill {
  name = "os__ejian",
}

Fk:loadTranslationTable{
  ["os__ejian"] = "恶荐",
  [":os__ejian"] = "当其他角色获得你的牌后，若其有除此牌以外与此牌类别相同的牌，你可以令其选择一项：1.弃置这些牌；"..
  "2.受到你造成的1点伤害。",

  ["#os__ejian-invoke"] = "恶荐：是否令 %dest 选择弃置牌或受到伤害？",
  ["#os__ejian-discard"] = "恶荐：弃置除获得的牌外和获得的牌类别相同的牌，或点“取消”%src 对你造成1点伤害",

  ["$os__ejian1"] = "为政者当沙汰秽浊，显拔幽滞，以顺民心。",
  ["$os__ejian2"] = "此所谓寡助之至，天下叛之矣。",
}

ejian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ejian.name) then
      local dat = {}
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand and not move.to.dead then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              dat[move.to] = dat[move.to] or {}
              table.insertIfNeed(dat[move.to], info.cardId)
            end
          end
        end
      end
      for to, ids in pairs(dat) do
        if table.find(ids, function (id)
          return table.find(to:getCardIds("he"), function (id2)
            return Fk:getCardById(id2).type == Fk:getCardById(id).type and not table.contains(ids, id2)
          end)
        end) then
          event:setCostData(self, {extra_data = dat})
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    local dat = event:getCostData(self).extra_data
    for p, _ in pairs(dat) do
      table.insertIfNeed(tos, p)
    end
    room:sortByAction(tos)
    for _, to in ipairs(tos) do
      if not player:hasSkill(ejian.name) then break end
      if not to.dead and table.find(dat[to], function (id)
          return table.find(to:getCardIds("he"), function (id2)
            return not table.contains(dat[to], id2) and Fk:getCardById(id2).type == Fk:getCardById(id).type
          end)
        end) then
        event:setCostData(self, {tos = {to}, cards = dat[to]})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room:askToSkillInvoke(player, {
      skill_name = ejian.name,
      prompt = "#os__ejian-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}, cards = event:getCostData(self).cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local all_cards = event:getCostData(self).cards
    local cards = table.filter(to:getCardIds("he"), function (id)
      return not table.contains(all_cards, id) and not player:prohibitDiscard(id) and
        table.find(all_cards, function (id2)
          return Fk:getCardById(id2).type == Fk:getCardById(id).type
        end)
    end)
    if #cards == 0 or not room:askToSkillInvoke(to, {
      skill_name = ejian.name,
      prompt = "#os__ejian-discard:"..player.id,
    }) then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = ejian.name,
      }
    else
      room:throwCard(cards, ejian.name, to, to)
    end
  end,
})

return ejian
