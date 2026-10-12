local xionghuo = fk.CreateSkill{
  name = "ofl_heg__xionghuo",
}

Fk:loadTranslationTable{
  ["ofl_heg__xionghuo"] = "凶镬",
  [":ofl_heg__xionghuo"] = "当你首次明置此武将牌后，你获得三枚“暴戾”标记。<br>"..
  "出牌阶段，你可以交给一名与你势力不同的角色一枚“暴戾”标记。<br>"..
  "每回合每名角色限一次，当你使用牌对拥有“暴戾”标记的其他角色造成伤害时，此伤害+1。<br>"..
  "拥有“暴戾”标记的其他角色出牌阶段开始时，其移去“暴戾”标记并随机执行一项：<br>"..
  "1.你对其造成1点火焰伤害，其本回合不能对你使用【杀】；<br>2.其失去1点体力且本回合手牌上限-1；<br>"..
  "3.你依次获得其装备区和手牌区各一张牌。",

  ["@ofl_heg__baoli"] = "暴戾",
  ["#ofl_heg__xionghuo"] = "凶镬：将“暴戾”交给其他角色",

  ["$ofl_heg__xionghuo1"] = "战场上的懦夫，可不会有好结局！",
  ["$ofl_heg__xionghuo2"] = "用最残忍的方式，碾碎敌人！",
}

local H = require "packages.hegemony.util"

xionghuo:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#ofl_heg__xionghuo",
  can_use = function(self, player)
    return player:getMark("@ofl_heg__baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      to_select:getMark("@ofl_heg__baoli") == 0 and
      not H.compareKingdomWith(player, to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:removePlayerMark(player, "@ofl_heg__baoli", 1)
    room:addPlayerMark(target, "@ofl_heg__baoli", 1)
  end,
})

xionghuo:addEffect(fk.GeneralRevealed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xionghuo.name) and player:usedSkillTimes(xionghuo.name, Player.HistoryGame) == 0 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), xionghuo.name) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ofl_heg__baoli", 3)
  end,
})

xionghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xionghuo.name) and
      data.to ~= player and data.to:getMark("@ofl_heg__baoli") > 0 and
      data.card and not table.contains(player:getTableMark("ofl_heg__xionghuo-turn"), data.to)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:changeDamage(1)
    room:addTableMark(player, "ofl_heg__xionghuo-turn", data.to)
  end,
})

xionghuo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xionghuo.name) and target ~= player and
      target:getMark("@ofl_heg__baoli") > 0 and target.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(target, "@ofl_heg__baoli", 0)
    local rand = math.random(1, target:isNude() and 2 or 3)
    if rand == 1 then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = xionghuo.name,
      }
      if not (player.dead or target.dead) then
        room:addTableMark(target, "ofl_heg__xionghuo_prohibit-turn", player)
      end
    elseif rand == 2 then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
      room:loseHp(target, 1, xionghuo.name, player)
    else
      if #target:getCardIds("e") > 0 then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "e",
          skill_name = xionghuo.name,
        })
        room:obtainCard(player, card, true, fk.ReasonPrey, player, xionghuo.name)
      end
      if not player.dead and not target:isKongcheng() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = xionghuo.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, xionghuo.name)
      end
    end
  end,
})

xionghuo:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and card.trueName == "slash" and from and table.contains(from:getTableMark("ofl_heg__xionghuo_prohibit-turn") , to)
  end,
})

xionghuo:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@ofl_heg__baoli", 0)
  end
end)

return xionghuo
