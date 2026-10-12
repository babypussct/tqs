local skill = fk.CreateSkill {
  name = "xuanjian_sword_skill&",
  attached_equip = "xuanjian_sword",
}

Fk:loadTranslationTable{
  ["xuanjian_sword_skill&"] = "玄剑",
  [":xuanjian_sword_skill&"] = "你可以将一种花色的所有手牌当【杀】使用。",
  ["#xuanjian_sword_skill"] = "玄剑：将一种花色的所有手牌当【杀】使用",
  ["#xuanjian_sword_skill_update"] = "玄剑：将一张手牌当【杀】使用",
}

---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

skill:addEffect("viewas", {
  pattern = "slash",
  prompt = function (self, player)
    if player:hasSkill("xushu__gongli") and GongliFriend(Fk:currentRoom(), player, "friend__zhugeliang") then
      return "#xuanjian_sword_skill_update"
    else
      return "#xuanjian_sword_skill"
    end
  end,
  interaction = function (self, player)
    if player:hasSkill("xushu__gongli") and GongliFriend(Fk:currentRoom(), player, "friend__zhugeliang") then
      return UI.CardNameBox {choices = {"slash"}}
    else
      local all_choices = {"log_spade", "log_heart", "log_club", "log_diamond"}
      local choices = table.filter(all_choices, function (s)
        local card = Fk:cloneCard("slash")
        card.skillName = skill.name
        local cards = table.filter(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getSuitString(true) == s
        end)
        card:addSubcards(cards)
        return #cards > 0 and player:canUse(card)
      end)
      return UI.ComboBox {choices = choices, all_choices = all_choices}
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if player:hasSkill("xushu__gongli") and GongliFriend(Fk:currentRoom(), player, "friend__zhugeliang") then
      return #selected == 0
    else
      return false
    end
  end,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = skill.name
    if player:hasSkill("xushu__gongli") and GongliFriend(Fk:currentRoom(), player, "friend__zhugeliang") then
      if #cards ~= 1 then return end
    else
      cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == self.interaction.data
      end)
      if #cards == 0 then return end
    end
    card:addSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    if player:hasSkill("xushu__gongli") and
      GongliFriend(room, player, "friend__zhugeliang") or GongliFriend(room, player, "friend__pangtong") then
      player:broadcastSkillInvoke("xushu__gongli")
      room:notifySkillInvoked(player, "xushu__gongli", "special")
    end
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

return skill
