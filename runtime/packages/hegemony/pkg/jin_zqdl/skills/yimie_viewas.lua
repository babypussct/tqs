local yimie_viewas = fk.CreateSkill {
  name = "heg__yimie_viewAs&",
}

Fk:loadTranslationTable {
  ["heg__yimie_viewAs&"] = "夷灭",
  [":heg__yimie_viewAs&"] = "与处于濒死状态角色势力不同的角色可将一张<font color='red'>♥</font>手牌当【桃】对处于濒死状态的角色使用。",
}

local H = require "packages.hegemony.util"

yimie_viewas:addEffect("viewas", {
  pattern = "peach",
  prompt = "#heg__yimie_prompt_use_peach",
  mute = true,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).suit == Card.Heart and
        table.contains(player:getCardIds("h"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("peach")
    card:addSubcard(cards[1])
    card.skillName = yimie_viewas.name
    return card
  end,
  after_use = function(self, player, use)
    local p = table.find(player.room:getAlivePlayers(), function(p)
      return p.phase ~= Player.NotActive and p:hasShownSkill("heg__yimie")
    end)
    if not p then return end
    player.room:notifySkillInvoked(p, "heg__yimie")
    p:broadcastSkillInvoke("heg__yimie")
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return p.phase ~= Player.NotActive and p:hasShownSkill("heg__yimie")
    end) and table.find(Fk:currentRoom().alive_players, function(p)
      return p.dying and H.compareKingdomWith(p, player, true)
    end)
  end
})

return yimie_viewas
