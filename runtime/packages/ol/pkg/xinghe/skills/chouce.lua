local chouce = fk.CreateSkill{
  name = "chouce",
}

Fk:loadTranslationTable{
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",

  ["#chouce-draw"] = "筹策：令一名角色摸一张牌（若为“先辅”角色则摸两张）",
  ["#chouce-discard"] = "筹策：弃置一名角色区域里的一张牌",

  ["$chouce1"] = "一筹一划，一策一略。",
  ["$chouce2"] = "主公之忧，吾之所思也。",
}

chouce:addEffect(fk.Damaged, {
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chouce.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = chouce.name,
      pattern = {
        [".|.|black,red"] = "good",
        [".|.|red"] = "red",
        [".|.|black"] = "black",
        ["else"] = "bad",
      },
    }
    room:judge(judge)
    if not judge.results or player.dead then return false end
    if table.contains(judge.results, "red") then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = chouce.name,
        prompt = "#chouce-draw",
        cancelable = false,
      })[1]
      local num = 1
      if player:getMark("xianfu") == to then
        num = 2
        room:setPlayerMark(player, "@[chara]xianfu", to.id)
      end
      to:drawCards(num, chouce.name)
    elseif table.contains(judge.results, "black") then
      local targets = table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = chouce.name,
        prompt = "#chouce-discard",
        cancelable = false,
      })[1]
      if to == player then
        local cards = table.filter(player:getCardIds("hej"), function (id)
          return not player:prohibitDiscard(id)
        end)
        cards = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = chouce.name,
          pattern = tostring(Exppattern{ id = cards }),
          cancelable = false,
          expand_pile = player:getCardIds("j"),
        })
        room:throwCard(cards, chouce.name, to, player)
      else
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "hej",
          skill_name = chouce.name,
        })
        room:throwCard(card, chouce.name, to, player)
      end
    end
  end,
})

chouce:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

chouce:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        if ai.data[2] == "#chouce-draw" then
          if p == ai.player:getMark("xianfu") then
            logic:drawCards(p, 2)
          else
            logic:drawCards(p, 1)
          end
        else
          local ret, _ = ai:askToChooseCards({
            cards = p:getCardIds("hej"),
            skill_name = self.skill_name,
            data = {
              toArea = Card.DiscardPile,
              reason = fk.ReasonDiscard,
              proposer = ai.player,
            }
          })
          logic:throwCard(ret, self.skill_name, p, ai.player)
        end
      end,
    })
    return ret
  end,
})

return chouce
