
local chonglei = fk.CreateSkill {
  name = "chonglei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chonglei"] = "冲垒",
  [":chonglei"] = "锁定技，你的出牌阶段内，所有其他角色的非基本手牌均只能作为【闪】使用或打出；"..
  "出牌阶段内限X次（X为其他角色数），当你使用的牌被其他角色响应后，或当你响应其他角色使用的牌后，你获得该角色一张手牌。",

  ["#chonglei-prey"] = "冲垒：获得 %dest 一张手牌",

  ["$chonglei1"] = "今日何须多言，不过一战而己！",
  ["$chonglei2"] = "纵对千峰万壑，亦当驱前踏破！",
}

---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

local spec = {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chonglei.name) and player.phase == Player.Play and
      data.responseToEvent and
      player:usedSkillTimes(chonglei.name, Player.HistoryPhase) < #player.room:getOtherPlayers(player, false) then
      if data.responseToEvent.from == player then
        if target ~= player and not target:isKongcheng() then
          event:setCostData(self, { tos = { target } })
          return true
        end
      else
        if target == player and not data.responseToEvent.from:isKongcheng() then
          event:setCostData(self, { tos = { data.responseToEvent.from } })
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = chonglei.name,
      prompt = "#chonglei-prey::"..to.id,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, chonglei.name, nil, false, player)
  end,
}
chonglei:addEffect(fk.CardUseFinished, spec)
chonglei:addEffect(fk.CardRespondFinished, spec)

chonglei:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    if Fk:currentRoom().current:hasSkill(chonglei.name) and Fk:currentRoom().current ~= player and
      Fk:currentRoom().current.phase == Player.Play and not player.dying and
      table.contains(player:getCardIds("h"), card.id) then
      return card.type ~= Card.TypeBasic or HeyuFriend(Fk:currentRoom(), Fk:currentRoom().current, "thoroughbred__yuejin")
    end
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("jink", card.suit, card.number)
  end,
})

return chonglei
