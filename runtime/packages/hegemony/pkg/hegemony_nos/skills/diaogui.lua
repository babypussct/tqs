
local diaogui = fk.CreateSkill {
  name = "nos_heg__diaogui",
}

Fk:loadTranslationTable {
  ["nos_heg__diaogui"] = "调归",
  [":nos_heg__diaogui"] = "出牌阶段限一次，你可以将一张装备牌当【调虎离山】使用，若你的势力因此而形成队列，你摸X张牌（X为该队列中的角色数）。",

  ["#nos_heg__diaogui"] = "调归：你可以将一张装备牌当【调虎离山】使用，若形成队列则摸牌",

  ["$nos_heg__diaogui1"] = "闻伯符立业，今特来相助。",
  ["$nos_heg__diaogui2"] = "臣虽驽钝，愿以此腔热血报国。",
}

local H = require "packages.hegemony.util"

diaogui:addEffect("viewas", {
  anim_type = "control",
  prompt = "#nos_heg__diaogui",
  pattern = "lure_tiger",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("lure_tiger")
    card.skillName = diaogui.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function (self, player, use)
    if not player.dead then
      local room = player.room
      local targets = table.filter(room.alive_players, function(p)
        return H.inFormationRelation(p, player) and p.kingdom ~= "unknown"
      end)
      if #targets > 0 then
        player:drawCards(#targets, diaogui.name)
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(diaogui.name, Player.HistoryPhase) == 0
  end,
})

return diaogui
