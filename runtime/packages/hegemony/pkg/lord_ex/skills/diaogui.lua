local diaogui = fk.CreateSkill {
  name = "ld__diaogui",
}

Fk:loadTranslationTable {
  ["ld__diaogui"] = "调归",
  [":ld__diaogui"] = "出牌阶段限一次，你可以将一张牌当【调虎离山】使用，然后若你的势力因此而形成队列，则此队列的角色各摸两张牌。",

  ["#ld__diaogui"] = "调归：你可以将一张牌当【调虎离山】使用，若形成队列则队列角色各摸两张牌",

  ["$ld__diaogui1"] = "闻伯符立业，今特来相助。",
  ["$ld__diaogui2"] = "臣虽驽钝，愿以此腔热血报国。",
}

local H = require "packages.hegemony.util"

diaogui:addEffect("viewas", {
  anim_type = "control",
  prompt = "#ld__diaogui",
  pattern = "lure_tiger",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
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
      local targets = table.filter(room:getAlivePlayers(), function(p)
        return H.inFormationRelation(p, player) and p.kingdom ~= "unknown"
      end)
      if #targets > 0 then
        for _, p in ipairs(targets) do
          if not p.dead then
            p:drawCards(2, diaogui.name)
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(diaogui.name, Player.HistoryPhase) == 0
  end,
})

return diaogui
