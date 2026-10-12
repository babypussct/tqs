local diaogui = fk.CreateSkill {
  name = "ld__diaogui",
}

Fk:loadTranslationTable {
  ["ld__diaogui"] = "调归",
  [":ld__diaogui"] = "出牌阶段限一次，你可将一张装备牌当【调虎离山】使用，然后若你的势力形成<a href='heg_formation_href'>队列</a>，则你摸X张牌（X为此队列中的角色数）。",

  ["#ld__diaogui"] = "调归：你可将一张装备牌当【调虎离山】使用",

  ["$ld__diaogui1"] = "闻伯符立业，今特来相助。",
  ["$ld__diaogui2"] = "臣虽驽钝，愿以此腔热血报国。",
}

local H = require "packages.hegemony.util"

diaogui:addEffect("viewas", {
  anim_type = "drawcard",
  prompt = "#ld__diaogui",
  pattern = "lure_tiger",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if Fk:getCardById(to_select) then
      return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("lure_tiger")
    c.skillName = diaogui.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(diaogui.name, Player.HistoryPhase) == 0
  end,
})

diaogui:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(diaogui.name) then
      if event == fk.CardUseFinished then
        return data.card and table.contains(data.card.skillNames, diaogui.name)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players,
      function(p)
        return H.inFormationRelation(p, player) and p.kingdom ~= "unknown"
      end)
    if #targets > 0 then
      player:drawCards(#targets, diaogui.name)
    end
  end,
})

return diaogui
