local songshu = fk.CreateSkill {
  name = "os__songshu",
}

Fk:loadTranslationTable {
  ["os__songshu"] = "颂蜀",
  [":os__songshu"] = "一名体力值不小于你的其他角色出牌阶段开始时，若“仁”区有至少X张牌，你可以观看其手牌并用X张“仁”区牌代替其中等量的牌" ..
      "（X为你的体力值，且最大为5）（原手牌置入弃牌堆）。若如此做，本回合其第一次使用牌指定自己为目标后，你可以令一名角色回复1点体力。",

  ["#os__songshu-invoke"] = "颂蜀：你可以观看 %dest 的手牌，用%arg张“仁”区牌代替其中等量的牌",
  ["#os__songshu-choose"] = "颂蜀：交换%arg张“仁”区和%dest手牌",
  ["#os__songshu-recover"] = "颂蜀：你可以令一名角色回复1点体力",
  ["@@os__songshu-turn"] = "颂蜀",

  ["$os__songshu1"] = "蜀中果多俊杰，恰闻讲论，令温顿开茅塞。",
  ["$os__songshu2"] = "贵国佐有高贤，战有良将，何愁胜事不传。",
}

local U = require "packages.utility.utility"

Fk:addPoxiMethod {
  name = "os__songshu",
  card_filter = function(to_select, selected, results, origCards)
    if #selected > 0 then
      local isBottom = table.contains(results[2], selected[1])
      local canSwap = {}
      if isBottom then
        canSwap = table.filter(results[1], function(id) return not table.contains(origCards[1], id) end)
      else
        canSwap = table.filter(results[2], function(id) return not table.contains(origCards[2], id) end)
      end
      local n = math.min(Self.hp, 5, #origCards[2])
      if #canSwap >= n then
        return table.contains(canSwap, to_select)
      end
    end
    return true
  end,
  feasible = function(_, results, origCards)
    return #table.filter(results[1], function(id) return not table.contains(origCards[1], id) end) <= math.min(Self.hp, 5)
  end,
}

local replaceWithRen = function(cards1, cards2, player, target, skillName)
  local room = player.room
  room:addSkill(Fk.skills["#RenPileTrigger"])
  local moves = {
    {
      ids = cards1,
      from = target,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skillName,
      moveVisible = true,
      proposer = player,
    },
    {
      ids = cards2,
      to = target,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      moveVisible = true,
      proposer = player,
    },
  }
  room:moveCards(table.unpack(moves))
end

songshu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(songshu.name) and target.phase == Player.Play and target ~= player and
        target.hp >= player.hp and #U.GetRenPile(player.room) >= math.min(player.hp, 5) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = songshu.name,
          prompt = "#os__songshu-invoke::" .. target.id .. ":" .. math.min(player.hp, 5, target:getHandcardNum()),
        }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ren = U.GetRenPile(room)
    local n = math.min(player.hp, 5, target:getHandcardNum())
    local results = room:askToArrangeCards(player, {
      skill_name = songshu.name,
      card_map = {
        ren, target:getCardIds("h"),
      },
      names = { "@$RenPile", target:toLogString() },
      prompt = "#os__songshu-choose::" .. target.id .. ":" .. n,
      poxi_type = "os__songshu",
      cancelable = false,
      free_arrange = false,
    })
    local cards1 = table.filter(results[1], function(id)
      return table.contains(target:getCardIds("h"), id)
    end)
    local cards2 = table.filter(results[2], function(id)
      return table.contains(ren, id)
    end)
    replaceWithRen(cards1, cards2, player, target, songshu.name)
    room:setPlayerMark(target, "@@os__songshu-turn", player)
  end,
})

songshu:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@os__songshu-turn") == player and data.to == target and
        target:usedEffectTimes(self.name) == 0 and
        table.find(player.room.alive_players, function(t) return t:isWounded() end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.filter(player.room.alive_players, function(t) return t:isWounded() end),
      min_num = 1,
      max_num = 1,
      skill_name = songshu.name,
      prompt = "#os__songshu-recover",
      cancelable = true,
    })
    if #tos > 0 then
      room:recover {
        who = tos[1],
        num = 1,
        from = player,
        skillName = songshu.name,
      }
    end
  end
})

return songshu
