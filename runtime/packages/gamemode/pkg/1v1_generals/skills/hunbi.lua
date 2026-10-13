local hunbi = fk.CreateSkill {
  name = "v11__hunbi",
}

Fk:loadTranslationTable{
  ["v11__hunbi"] = "魂弼",
  [":v11__hunbi"] = "当你死亡时，若对手的流放区未饱和，你可以令你下一名武将登场时选择一项：1.视为使用一张【杀】；2.摸一张牌；"..
  "3.对对手执行至多两次流放。",

  ["#v11__hunbi_slash"] = "视为使用【杀】",
  ["#v11__hunbi_exile"] = "对对手执行两次流放",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

hunbi:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(hunbi.name, false, true) then
      local rest = player.room:getBanner(player.next.role == "lord" and "@&firstExiled" or "@&secondExiled") or {}
      return #rest < 3
    end
  end,
  on_use = function(self, event, target, player, data)
    player.tag["v11__hunbi"] = true
  end,
})

hunbi:addEffect(U.Debut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.tag["v11__hunbi"]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.tag["v11__hunbi"] = false
    local to = player.next
    local all_choices = {"draw1", "#v11__hunbi_slash", "#v11__hunbi_exile"}
    local choices = table.simpleClone(all_choices)
    if not player:canUseTo(Fk:cloneCard("slash"), to, {bypass_distances = true, bypass_times = true}) then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = hunbi.name,
      all_choices = all_choices,
    })
    if choice == all_choices[1] then
      player:drawCards(1, hunbi.name)
    elseif choice == all_choices[2] then
      room:useVirtualCard("slash", nil, player, to, hunbi.name, true)
    else
      for _ = 1, 2 do
        U.exilePlayer(player, to)
      end
    end
  end,
})

return hunbi
