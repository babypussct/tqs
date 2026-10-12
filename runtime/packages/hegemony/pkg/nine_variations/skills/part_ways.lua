
local skill = fk.CreateSkill {
  name = "part_ways_skill",
}

local H = require "packages.hegemony.util"

skill:addEffect("cardskill", {
  prompt = "#part_ways_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and H.compareKingdomWith(to_select, player)
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if not player.dead then
      player:drawCards(6, skill.name)
    end
    if not target.dead and not player:isNude() then
      local cards = room:askToCards(player, {
        min_num = 3,
        max_num = 3,
        include_equip = true,
        skill_name = skill.name,
        cancelable = false,
        prompt = "#part_ways-give::"..target.id,
      })
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, skill.name, nil, false, player)
    end
    if not player.dead then
      if room:isGameMode("heg_mode") then
        H.wildChooseKingdom(player, player.general ~= "anjiang" and player.general or player.deputyGeneral)
      else -- 适配手杀身份局野心家的，放在哪合适？
        room:setPlayerProperty(player, "role_shown", true)
        room:changeRole(player, "wild")
        room:addPlayerMark(player, "@!!m_role_wild", 1)
        room:handleAddLoseSkills(player, "m_role_wild_draw&", nil, false, true)
      end
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.5,
  use_value = 15,
  use_priority = 12,

  on_effect = function(self, logic, effect)
    logic:drawCards(effect.from, 3, skill.name)
    logic:drawCards(effect.to, 3, skill.name)
  end,
})

return skill
