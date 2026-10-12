local binglun = fk.CreateSkill {
  name = "binglun",
}

Fk:loadTranslationTable{
  ["binglun"] = "病论",
  [":binglun"] = "出牌阶段限一次，你可以移去一张“仁”牌，令一名角色选择一项：1.摸一张牌；2.其下个回合结束时回复1点体力。",

  ["#binglun"] = "病论：你可以移去一张“仁”区牌，令一名角色选择摸牌或其回合结束时回复体力",
  ["binglun_recover"] = "你下个回合结束时回复1点体力",

  ["$binglun1"] = "受病有深浅，使药有重轻。",
  ["$binglun2"] = "三分需外治，七分靠内养。",
}

local U = require "packages.utility.utility"

binglun:addEffect("active", {
  anim_type = "support",
  prompt = "#binglun",
  card_num = 1,
  target_num = 1,
  expand_pile = function ()
    return U.GetRenPile(Fk:currentRoom())
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(binglun.name, Player.HistoryPhase) == 0 and #U.GetRenPile(Fk:currentRoom()) > 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(Fk:currentRoom():getBanner("@$RenPile"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonDiscard, binglun.name, nil, true, player)
    if target.dead then return end
    local choices = {"draw1", "binglun_recover"}
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = binglun.name,
    })
    if choice == "draw1" then
      target:drawCards(1, binglun.name)
    else
      room:addPlayerMark(target, binglun.name, 1)
    end
  end,
})
binglun:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark(binglun.name) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = player:getMark(binglun.name)
    room:setPlayerMark(player, binglun.name, 0)
    if player:isWounded() then
      room:recover({
        who = player,
        num = math.min(n, player.maxHp - player.hp),
        recoverBy = player,
        skillName = binglun.name,
      })
    end
  end,
})

return binglun
