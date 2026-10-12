local zhuwei = fk.CreateSkill{
  name = "ld__zhuwei",
}

Fk:loadTranslationTable{
  ["ld__zhuwei"] = "筑围",
  [":ld__zhuwei"] = "出牌阶段限一次，你可以弃置两张牌并选择一名角色，若该角色死亡可以令场上形成新的围攻关系，你对其造成2点伤害，否则你摸一张牌。",

  ["$ld__zhuwei1"] = "背水一战，只为破敌。",
  ["$ld__zhuwei2"] = "全线并进，连战克晋。",
}

local H = require "packages.hegemony.util"

zhuwei:addEffect("active", {
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuwei.name, Player.HistoryPhase) == 0 and
      #table.filter(player:getCardIds("he"), function(id)
        return not player:prohibitDiscard(id)
      end) >= 2
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("he"), to_select)
    and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, zhuwei.name, player, player)
    if player.dead or target.dead then return end
    local previous = target:getLastAlive()
    local next_player = target:getNextAlive()
    local previous_attacker = previous:getLastAlive()
    local next_attacker = next_player:getNextAlive()
    local creates_siege = H.compareKingdomWith(previous, next_player, true) and
    (H.compareKingdomWith(previous_attacker, next_player) or H.compareKingdomWith(previous, next_attacker))
    if creates_siege then
      room:damage {
        from = player,
        to = target,
        damage = 2,
        skillName = zhuwei.name,
      }
    else
      player:drawCards(1, zhuwei.name)
    end
  end,
})

return zhuwei
