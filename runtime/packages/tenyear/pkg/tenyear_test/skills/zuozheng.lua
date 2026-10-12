
local zuozheng = fk.CreateSkill {
  name = "zuozheng",
}

Fk:loadTranslationTable{
  ["zuozheng"] = "佐政",
  [":zuozheng"] = "其他角色出牌阶段开始时，若其手牌数不大于你，你可以观看其手牌并使用其中一张牌，若其本阶段使用的下一张牌与此牌目标或类型相同，"..
  "你选择与其各获得一张同类型牌或各回复1点体力，若不同，你不可使用与此牌颜色相同的牌直到此回合结束。",

  ["#zuozheng-invoke"] = "佐政：你可以观看 %dest 的手牌并使用其中一张牌",
  ["#zuozheng-use"] = "佐政：使用 %dest 的一张手牌，其本阶段使用下一张牌时执行效果",
  ["#zuozheng-choice"] = "佐政：选择与 %dest 执行的一项",
  ["zuozheng_draw"] = "获得一张%arg",
  ["zuozheng_recover"] = "回复1点体力",
  ["@zuozheng-turn"] = "禁用",

  ["$zuozheng1"] = "",
  ["$zuozheng2"] = "",
}

zuozheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zuozheng.name) and target.phase == Player.Play and
      not target:isKongcheng() and target:getHandcardNum() <= player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zuozheng.name,
      prompt = "#zuozheng-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(target:getCardIds("h"))
    local yes = table.find(cards, function (id)
      return #Fk:getCardById(id):getDefaultTarget(player, { bypass_times = true }) > 0
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = zuozheng.name,
      prompt = "#zuozheng-use::"..target.id,
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      },
      skip = true,
      cancelable = not yes,
    })
    if use then
      room:setPlayerMark(player, "zuozheng-phase", use)
      room:useCard(use)
    end
  end,
})

zuozheng:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zuozheng.name) and
      player:getMark("zuozheng-phase") ~= 0 and target.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = player:getMark("zuozheng-phase")
    room:setPlayerMark(player, "zuozheng-phase", 0)
    local yes = use.card.type == data.card.type
    if not yes then
      if #use.tos == #data.tos and
        table.every(use.tos, function (p)
          return table.contains(data.tos, p)
        end) and
        table.every(data.tos, function (p)
          return table.contains(use.tos, p)
        end) then
        yes = true
      end
    end
    if yes then
      local choice = room:askToChoice(player, {
        choices = { "zuozheng_draw:::"..use.card:getTypeString(), "zuozheng_recover" },
        skill_name = zuozheng.name,
        prompt = "#zuozheng-choice::"..target.id,
      })
      if choice:startsWith("zuozheng_draw") then
        for _, p in ipairs({ player, target }) do
          if not p.dead then
            local card = room:getCardsFromPileByRule(".|.|.|.|.|"..use.card:getTypeString())
            if #card > 0 then
              room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonJustMove, zuozheng.name, nil, false, player)
            end
          end
        end
      else
        for _, p in ipairs({ player, target }) do
          if not p.dead then
            room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = zuozheng.name
            }
          end
        end
      end
    else
      room:addTableMarkIfNeed(player, "@zuozheng-turn", use.card:getColorString())
    end
  end,
})

zuozheng:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and
      table.find(player:getTableMark("@zuozheng-turn"), function(color)
        return card:matchVSPattern(".|.|"..color)
      end)
  end,
})

return zuozheng
