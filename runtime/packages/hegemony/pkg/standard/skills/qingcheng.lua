
local qingcheng = fk.CreateSkill{
  name = "qingcheng",
}

Fk:loadTranslationTable{
  ["qingcheng"] = "倾城",
  [":qingcheng"] = "出牌阶段，你可以弃置一张黑色牌并选择一名武将牌均明置的其他角色，然后你暗置其一张武将牌。"..
  "然后若你以此法弃置的牌是黑色装备牌，则你可以再选择另一名武将牌均明置的其他角色，暗置其一张武将牌。",

  ["#qingcheng-again"] = "倾城：你可以再暗置一名角色的一张武将牌",

  ["$qingcheng1"] = "我和你们真是投缘啊。",
  ["$qingcheng2"] = "哼，眼睛都直了呀。",
}

local H = require "packages.hegemony.util"

qingcheng:addEffect("active", {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected > 0 or #selected_cards == 0 then return false end --TODO
    return to_select ~= player and to_select.general ~= "anjiang" and to_select.deputyGeneral ~= "anjiang"
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local ret = false
    if Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      ret = true
    end
    room:throwCard(effect.cards, self.name, player, player)
    H.doHideGeneral(room, player, target, self.name)
    if ret and not player.dead then
      local targets = table.filter(room.alive_players, function(p)
        return p.general ~= "anjiang" and p.deputyGeneral ~= "anjiang" and p ~= player and p ~= target
      end)
      if #targets == 0 then return false end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = qingcheng.name,
        prompt = "#qingcheng-again",
        cancelable = true,
      })
      if #to > 0 then
        H.doHideGeneral(room, player, to[1], self.name)
      end
    end
  end,
})

return qingcheng
