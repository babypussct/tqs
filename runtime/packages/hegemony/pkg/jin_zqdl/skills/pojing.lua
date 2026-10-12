
local pojing = fk.CreateSkill{
  name = "heg__pojing",
}

Fk:loadTranslationTable{
  ["heg__pojing"] = "迫境",
  [":heg__pojing"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你获得其区域内的一张牌；2.所有与你势力相同的角色可以明置任意张"..
  "武将牌，对其造成等量的伤害。",

  ["#heg__pojing"] = "迫境：令一名角色选择你获得其区域内一张牌，或与你势力相同的角色可以亮将并对其造成伤害",
  ["heg__pojing_prey"] = "%src获得你区域内一张牌",
  ["heg__pojing_damage"] = "与%src势力相同的角色可以明置武将牌，对你造成伤害",
  ["#heg__pojing-ask"] = "迫境：你可以明置任意张武将牌，对 %dest 造成等量伤害",

  ["$heg__pojing1"] = "奉命伐吴，得胜纳降。",
  ["$heg__pojing2"] = "进军逼江，震慑吴贼。",
}

local H = require "packages.hegemony.util"

pojing:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__pojing",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = { "heg__pojing_damage:"..player.id }
    if not target:isAllNude() then
      table.insert(choices, 1, "heg__pojing_prey:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = pojing.name,
    })
    if choice:startsWith("heg__pojing_prey") then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = pojing.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, pojing.name, nil, false, player)
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead and H.compareKingdomWith(player, p, false) then
          local result = H.askToRevealGenerals(p, {
            skill_name = pojing.name,
            prompt = "#heg__pojing-ask::"..target.id,
          })
          if result ~= "Cancel" and not target.dead then
            local n = result == "md" and 2 or 1
            room:damage{
              from = p,
              to = target,
              damage = n,
              skillName = pojing.name,
            }
          end
        end
      end
    end
  end,
})

return pojing
