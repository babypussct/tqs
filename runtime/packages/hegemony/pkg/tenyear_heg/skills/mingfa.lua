
local mingfa = fk.CreateSkill{
  name = "ty_heg__mingfa",
}
local H = require "packages.hegemony.util"
mingfa:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(mingfa.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not H.compareKingdomWith(to_select, player)
  end,
  on_use = function(self, room, effect)
    room:addTableMark(effect.tos[1], "@@ty_heg__mingfa_delay", effect.from.id)
  end,
})

mingfa:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target.dead or player.dead then return false end
    return table.contains(target:getTableMark("@@ty_heg__mingfa_delay"), player.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > target:getHandcardNum() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = mingfa.name,
      }
      if target:getHandcardNum() > 0 then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = mingfa.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    elseif player:getHandcardNum() < target:getHandcardNum() then
      player:drawCards(math.min(target:getHandcardNum() - player:getHandcardNum(), 5), mingfa.name)
    end
  end,
})
mingfa:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@@ty_heg__mingfa_delay") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ty_heg__mingfa_delay", 0)
  end,
})
mingfa:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@@ty_heg__mingfa_delay")
    return type(mark) == "table" and table.every(player.room.alive_players, function (p)
      return not table.contains(mark, p.id)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ty_heg__mingfa_delay", 0)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__mingfa"] = "明伐",
  [":ty_heg__mingfa"] = "出牌阶段限一次，你可以选择与你势力不同或未确定势力的一名其他角色，其下个回合结束时，若其手牌数：小于你，你对其造成1点伤害并获得其一张手牌；"..
  "不小于你，你摸至与其手牌数相同（最多摸五张）。",
  ["@@ty_heg__mingfa_delay"] = "明伐",
  ["$ty_heg__mingfa1"] = "煌煌大势，无须诈取。",
  ["$ty_heg__mingfa2"] = "开示公道，不为掩袭。",
}

return mingfa
