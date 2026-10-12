local zhiwei = fk.CreateSkill{
  name = "ty_heg__zhiwei",
}

local H = require "packages.hegemony.util"

---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
local function zhiweiUpdate(room, player, target)
  room:setPlayerMark(player, zhiwei.name, target.id)
  room:setPlayerMark(player, "@zhiwei", target.general == "anjiang" and "seat#" .. tostring(target.seat) or target.general)
end

zhiwei:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) and target == player and player:getMark("@zhiwei") == 0 then
      for _, v in pairs(data) do
        if v == "ty_heg__luyusheng" then return true end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = player.room:getOtherPlayers(player, false)
    if #targets == 0 then return false end
    local to = player.room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1, prompt = "#ty_heg__zhiwei-choose", skill_name = zhiwei.name})
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    zhiweiUpdate(room, player, event:getCostData(self).tos[1])
  end,
})
zhiwei:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      if player.phase ~= Player.Discard then return false end
      local zhiwei_id = player:getMark(zhiwei.name)
      if zhiwei_id == 0 then return false end
      local room = player.room
      local to = room:getPlayerById(zhiwei_id)
      if to == nil or to.dead then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local zhiwei_id = player:getMark(zhiwei.name)
    if zhiwei_id == 0 then return false end
    local to = room:getPlayerById(zhiwei_id)
    if to == nil or to.dead then return false end
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      zhiweiUpdate(room, player, to)
      room:moveCards({
        ids = cards,
        to = zhiwei_id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player,
        skillName = zhiwei.name,
      })
    end
  end,
})
zhiwei:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return target and player:getMark(zhiwei.name) == target.id and not target.dead
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    zhiweiUpdate(room, player, target)
    room:drawCards(player, 1, zhiwei.name)
  end,
})
zhiwei:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return target and player:getMark(zhiwei.name) == target.id and not target.dead and not player:isKongcheng()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    zhiweiUpdate(room, player, target)
    if not player:isKongcheng() then
      room:throwCard(table.random(player:getCardIds("h"), 1), zhiwei.name, player, player)
    end
  end,
})
zhiwei:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(zhiwei.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, zhiwei.name, 0)
    room:setPlayerMark(player, "@zhiwei", 0)
    H.hideBySkillName(player, zhiwei.name)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__zhiwei"] = "至微",
  [":ty_heg__zhiwei"] = "当你明置此武将牌后，你可选择一名其他角色：当该角色造成伤害后，你摸一张牌；当该角色受到伤害后，你随机弃置一张手牌；"..
  "你弃牌阶段弃置的牌均被该角色获得；当该角色死亡时，若你武将牌均明置，你暗置此武将牌。",

  ["#ty_heg__zhiwei-choose"] = "至微：选择一名其他角色",
  ["@ty_heg__zhiwei"] = "至微",

  ["$ty_heg__zhiwei1"] = "体信贯于神明，送终以礼。",
  ["$ty_heg__zhiwei2"] = "昭德以行，生不能侍奉二主。",
}

return zhiwei
