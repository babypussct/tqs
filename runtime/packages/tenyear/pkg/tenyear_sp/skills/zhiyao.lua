local zhiyao = fk.CreateSkill {
  name = "zhiyao",
  max_branches_use_time = function(self, player)
    local ret = {}
    for _, to in ipairs(Fk:currentRoom().players) do
      ret[tostring(to.id)] = {
        [Player.HistoryPhase] = 1,
      }
    end
    return ret
  end
}

Fk:loadTranslationTable{
  ["zhiyao"] = "制肴",
  [":zhiyao"] = "出牌阶段对每名角色各限一次，你可以弃置任意张【桃】、【酒】、【顺手牵羊】、【五谷丰登】或坐骑牌并选择一名角色，"..
    "每弃置一张牌令其判定两次，若结果为：<font color='red'>♥</font>，其获得此判定牌并回复1点体力；"..
    "<font color='red'>♦</font>，你对其造成1点火焰伤害；♣，其获得此判定牌并使用此牌时无次数限制；♠，其随机弃置两张牌。",

  ["#zhiyao-active"] = "制肴：弃置任意张食物牌并令一名角色进行两倍数量的判定",
  ["@@zhiyao-inhand"] = "制肴",

  ["$zhiyao1"] = "",
  ["$zhiyao2"] = "",
}

zhiyao:addEffect("active", {
  anim_type = "support",
  prompt = "#zhiyao-active",
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return table.contains({"peach", "analeptic", "snatch", "amazing_grace"}, card.trueName) or
    table.contains({Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide}, card.sub_type)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and zhiyao:withinBranchTimesLimit(player, tostring(to_select.id), Player.HistoryPhase)
  end,
  history_branch = function(self, player, data)
    return tostring(data.tos[1].id)
  end,
  on_use = function(self, room, effect)
    local toThrow = effect.cards
    local player = effect.from
    local to = effect.tos[1]
    local skillName = zhiyao.name
    room:throwCard(toThrow, skillName, player, player)
    local x = 2*#toThrow
    for _ = 1, x do
      if not to:isAlive() then break end
      local judge = {
        who = to,
        reason = skillName,
        pattern = {}
      }
      for _, suit in ipairs({ "heart", "diamond", "club", "spade" }) do
        judge.pattern[".|.|" .. suit] = suit
      end
      room:judge(judge)
      if not to:isAlive() then break end
      if judge.results then
        if table.contains(judge.results, "heart") then
          if judge.card and table.contains(room.discard_pile, judge.card.id) then
            room:obtainCard(to, judge.card, true, fk.ReasonJustMove, to, skillName)
            if not to:isAlive() then break end
          end
          if to:isWounded() then
            room:recover { who = to, num = 1, skillName = skillName, recoverBy = player }
          end
        elseif table.contains(judge.results, "diamond") then
          room:damage { from = player, to = to, damage = 1, skillName = skillName, damageType = fk.FireDamage }
        elseif table.contains(judge.results, "club") then
          if judge.card and table.contains(room.discard_pile, judge.card.id) then
            room:obtainCard(to, judge.card, true, fk.ReasonJustMove, to, skillName, "@@zhiyao-inhand")
          end
        elseif table.contains(judge.results, "spade") then
          local cards = table.filter(to:getCardIds("he"), function(id)
            return not to:prohibitDiscard(id)
          end)
          if #cards > 0 then
            room:throwCard(room:tableRandomPick(cards, 2), skillName, to, to)
          end
        end
      end
    end
  end,
})

zhiyao:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:hasMark("@@zhiyao-inhand")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end
})

zhiyao:addEffect("targetmod", {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@zhiyao-inhand") > 0
  end,
})

return zhiyao
