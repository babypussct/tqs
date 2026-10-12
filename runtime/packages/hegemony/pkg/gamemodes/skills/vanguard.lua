local vanguardSkill = fk.CreateSkill{
  name = "vanguard_skill&",
}
local H = require "packages.hegemony.util"
vanguardSkill:addEffect("active", {
  prompt = "#vanguard_skill&",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("@!!vanguard") > 0
  end,
  card_filter = Util.FalseFunc,
  target_num = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p) return
      (p.general == "anjiang" or p.deputyGeneral == "anjiang") and p ~= player
    end) and 1 or 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if to_select ~= player and #selected == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return (p.general == "anjiang" or p.deputyGeneral == "anjiang") and p ~= player
      end) then
        return to_select.general == "anjiang" or to_select.deputyGeneral == "anjiang"
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    H.removeHegMark(room, player, "vanguard", 1)
    local num = 4 - player:getHandcardNum()
    if num > 0 then
      player:drawCards(num, vanguardSkill.name)
    end
    if #effect.tos == 0 or player.dead then return false end
    local target = effect.tos[1]
    local choices = {"known_both_main", "known_both_deputy"}
    if target.general ~= "anjiang" then
      table.remove(choices, 1)
    end
    if target.deputyGeneral ~= "anjiang" then
      table.remove(choices)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = vanguardSkill.name,
      prompt = "#known_both-choice::"..target.id,
    })
    H.viewGeneral(player, target, vanguardSkill.name, choice == "known_both_main", choice == "known_both_deputy")
  end,
})

Fk:loadTranslationTable{
  ["vanguard_skill&"] = "先驱",
  ["#vanguard_skill&"] = "你可弃一枚“先驱”，将手牌摸至4张，观看一名其他角色的一张暗置武将牌",
  [":vanguard_skill&"] = "出牌阶段，你可弃一枚“先驱”，将手牌摸至4张，观看一名其他角色的一张暗置武将牌。",
  ["vanguard"] = "先驱",
}

return vanguardSkill
