local mutao = fk.CreateSkill{
  name = "mobile__mutao",
}

Fk:loadTranslationTable{
  ["mobile__mutao"] = "募讨",
  [":mobile__mutao"] = "出牌阶段限一次，你可以选择一名角色，令其将手牌中所有的【杀】置于其武将牌上，"..
  "然后其依次将这些【杀】随机交给由其下家开始的每一名角色，然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为2）。",

  ["#mobile__mutao"] = "募讨：选择一名角色分发其手牌中的【杀】，对最后一名角色造成伤害",
  ["$mutao"] = "募讨",

  ["$mobile__mutao1"] = "今起义兵，只为还天下清明！",
  ["$mobile__mutao2"] = "董贼不除，汉室如何可兴？",
}

mutao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__mutao",
  can_use = function(self, player)
    return player:usedSkillTimes(mutao.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng() and to_select:getNextAlive() ~= to_select
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local to = target
    local cids = table.filter(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)

    if #cids == 0 then
      return false
    end

    target:addToPile("$mutao", cids, true, mutao.name, to)
    if not target:isAlive() or #target:getPile("$mutao") == 0 then
      return false
    end

    cids = target:getPile("$mutao")
    local num = #cids
    for _ = 1, num do
      if #cids < 1 then break end
      to = to:getNextAlive()
      local id = room:tableRandomPick(cids)
      room:moveCardTo(id, Player.Hand, to, fk.ReasonGive, mutao.name, nil, false)
      cids = target:getPile("$mutao")
    end
    num = math.min(#table.filter(to:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end), 2)
    if num > 0 and not to.dead then
      room:damage{
        from = target,
        to = to,
        damage = num,
        skillName = mutao.name,
      }
    end
  end,
})

mutao:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local ret, benefit = nil, 0
    for _, p in ipairs(ai:getEnabledTargets()) do
      local tmp = 0
      local cards = table.filter(p:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cards > 0 then
        tmp = ai:getBenefitOfEvents(function(logic)
          local to = p
          for i = 1, #cards do
            to = to:getNextAlive()
            logic:moveCardTo(cards[i], Card.PlayerHand, to, fk.ReasonGive)
          end
          local num = math.min(1 + #table.filter(to:getCardIds("h"), function(id)
            return Fk:getCardById(id).trueName == "slash"
          end), 2)
          logic:damage{
            from = p,
            to = to,
            damage = num,
          }
        end)
      end
      if tmp >= benefit then
        ret, benefit = p, tmp
      end
    end
    if ret then
      return { { }, { ret } }, benefit
    end
  end,
})

return mutao
