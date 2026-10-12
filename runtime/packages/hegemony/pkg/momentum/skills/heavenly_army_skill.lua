local heavenly_army_skill = fk.CreateSkill{
  name = "heavenly_army_skill&",
}
local H = require "packages.hegemony.util"

Fk:loadTranslationTable{
  ["heavenly_army"] = "天兵",
  ["heavenly_army_skill&"] = "天兵符",
  [":heavenly_army_skill&"] = "你可以将一张“天兵”当【杀】使用或打出。",
  ["#heavenly_army_skill-active"] = "黄巾天兵符：你可以将一张“天兵”当【杀】使用或打出",
  ["#heavenly_army_skill-ask"] = "黄巾天兵符：你可以移去一张“天兵”，防止此次失去体力",
}

local heavenly_army_enabled = function(self, player)
  for _, p in ipairs(Fk:currentRoom().alive_players) do
    if string.find(p.general, "lord") and p:hasSkill("hongfa") and p.kingdom == player.kingdom and #p:getPile("heavenly_army") > 0 then
      return true
    end
  end
end
heavenly_army_skill:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  mute_card = true,
  prompt = "#heavenly_army_skill-active",
  interaction = function(self, player)
    local cards = {}
    local kingdom = player.kingdom
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if string.find(p.general, "lord") and p:hasSkill("hongfa") and p.kingdom == kingdom and #p:getPile("heavenly_army") > 0 then
        cards = table.map(p:getPile("heavenly_army"), function(id) return Fk:getCardById(id):toLogString() end)
        break
      end
    end
    if #cards == 0 then return end
    return UI.ComboBox {choices = cards} -- FIXME: expand_pile
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard("slash")
    card.skillName = heavenly_army_skill.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = {}
    local kingdom = player.kingdom
    for _, p in ipairs(room.alive_players) do
      if string.find(p.general, "lord") and p:hasSkill("hongfa") and p.kingdom == kingdom and #p:getPile("heavenly_army") > 0 then
        cards = p:getPile("heavenly_army")
        break
      end
    end
    local card
    for _, id in ipairs(cards) do
      if Fk:getCardById(id):toLogString() == self.interaction.data then
        card = id
        break
      end
    end
    use.card:addSubcard(card)
    player:broadcastSkillInvoke("hongfa", math.random(4, 5))
    return
  end,
  enabled_at_play = heavenly_army_enabled,
  enabled_at_response = heavenly_army_enabled,
})


heavenly_army_skill:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(heavenly_army_skill.name) and player:hasSkill("hongfa")) then return end
    return player.phase == Player.Start and #player:getPile("heavenly_army") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("hongfa", math.random(2, 3))
    room:notifySkillInvoked(player, "heavenly_army_skill&", "control")
    player:addToPile("heavenly_army", room:getNCards(H.getSameKingdomPlayersNum(room, nil, "qun")
      + #player:getPile("heavenly_army")), true, heavenly_army_skill.name)
  end,
})

heavenly_army_skill:addEffect(fk.PreHpLost, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(heavenly_army_skill.name) and player:hasSkill("hongfa")) then return end
    return #player:getPile("heavenly_army") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askToCards(player, {
      min_num = 1, max_num = 1, include_equip = false, skill_name = heavenly_army_skill.name,
      cancelable = true, pattern = ".|.|.|heavenly_army", prompt = "#heavenly_army_skill-ask",
      expand_pile = "heavenly_army"}
    )
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("hongfa", 6)
    room:notifySkillInvoked(player, "heavenly_army_skill&", "defensive")
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, heavenly_army_skill.name, "heavenly_army", true, player.id)
    data:preventHpLost()
  end,
})

return heavenly_army_skill
