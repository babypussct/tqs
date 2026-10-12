local zhongyong = fk.CreateSkill{
  name = "m_ex__zhongyong",
}

Fk:loadTranslationTable{
  ["m_ex__zhongyong"] = "忠勇",
  [":m_ex__zhongyong"] = "当你于出牌阶段内使用【杀】结算结束后，若没有目标角色使用【闪】响应过此【杀】，你可以重新获得此【杀】，"..
    "否则你可以选择：1.获得响应此【杀】的【闪】，然后你可以将此【杀】交给另一名其他角色；"..
    "2.将响应此【杀】的【闪】交给另一名其他角色，然后你本阶段使用【杀】的次数上限+1，你本阶段使用的下一张【杀】基础伤害值+1。"..
    "你不能使用本回合通过〖忠勇〗获得的牌。",

  ["#m_ex__zhongyong-slash"] = "忠勇：是否收回使用的 %arg",
  ["#m_ex__zhongyong-jink"] = "忠勇：你可以获得或交出【闪】，然后获得一些其他效果",
  ["m_ex__zhongyong_self"] = "获得【闪】",
  ["m_ex__zhongyong_other"] = "交出【闪】",
  ["#m_ex__zhongyong-choose"] = "忠勇：将所有响应此【杀】的【闪】交给1名角色",
  ["@@m_ex__zhongyong-inhand-turn"] = "忠勇",
  ["#m_ex__zhongyong-give"] = "忠勇：选择1名角色，令其获得你使用的 %arg",

  ["$m_ex__zhongyong1"] = "关将军，接刀！",
  ["$m_ex__zhongyong2"] = "青龙三停刀，斩敌万千条！",
}

zhongyong:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and data.card.trueName == "slash" and player:hasSkill(zhongyong.name) then
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local jinks = {}
      logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        local use = e.data
        --FIXME：堆叠使用两张相同的【杀】的场合似乎会误判
        if use.card.trueName == "jink" and use.toCard == data.card then
          table.insert(jinks, use.card)
        end
      end, use_event.id)
      if #jinks == 0 then
        if room:getCardArea(data.card) == Card.Processing then
          event:setCostData(self, {cards = Card:getIdList(data.card), choice = "slash"})
          return true
        end
      else
        local ids = {}
        for _, card in ipairs(jinks) do
          for _, id in ipairs(Card:getIdList(card)) do
            if not table.contains(ids, id) and room:getCardArea(id) == Card.DiscardPile then
              table.insert(ids, id)
            end
          end
        end
        if #ids > 0 then
          event:setCostData(self, {cards = ids, choice = "jink"})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    if dat.choice == "slash" then
      return room:askToSkillInvoke(player, {
        skill_name = zhongyong.name,
        prompt = "#m_ex__zhongyong-slash:::" .. data.card:toLogString()
      })
    else
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not table.contains(data.tos, p)
      end)
      local choices = {"m_ex__zhongyong_self", "Cancel"}
      if #targets > 0 then
        table.insert(choices, "m_ex__zhongyong_other")
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhongyong.name,
        prompt = "#m_ex__zhongyong-jink",
        all_choices = {"m_ex__zhongyong_self", "m_ex__zhongyong_other", "Cancel"}
      })
      if choice == "m_ex__zhongyong_self" then
        return true
      elseif choice == "m_ex__zhongyong_other" then
        targets = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = zhongyong.name,
          prompt = "#m_ex__zhongyong-choose",
          cancelable = true
        })
        if #targets > 0 then
          dat.tos = targets
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    if dat.choice == "slash" then
      room:obtainCard(player, dat.cards, true, fk.ReasonJustMove, player, zhongyong.name, "@@m_ex__zhongyong-inhand-turn")
    else
      if dat.tos then
        room:obtainCard(dat.tos[1], dat.cards, true, fk.ReasonGive, player, zhongyong.name)
        if not player.dead then
          room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
          room:setPlayerMark(player, "m_ex__zhongyong_effect-phase", 1)
        end
      else
        room:obtainCard(player, dat.cards, true, fk.ReasonJustMove, player, zhongyong.name, "@@m_ex__zhongyong-inhand-turn")
        if not player.dead and room:getCardArea(data.card) == Card.Processing then
          local tos = table.filter(room.alive_players, function (p)
            return p ~= player and not table.contains(data.tos, p)
          end)
          if #tos > 0 then
            tos = room:askToChoosePlayers(player, {
              min_num = 1,
              max_num = 1,
              targets = tos,
              skill_name = zhongyong.name,
              prompt = "#m_ex__zhongyong-give:::" .. data.card:toLogString(),
              cancelable = false
            })
            room:obtainCard(tos[1], data.card, true, fk.ReasonGive, player, zhongyong.name)
          end
        end
      end
    end
  end,
})

zhongyong:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("m_ex__zhongyong_effect-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "m_ex__zhongyong_effect-phase", 0)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

zhongyong:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return table.find(Card:getIdList(card), function (id)
      return Fk:getCardById(id):getMark("@@m_ex__zhongyong-inhand-turn") ~= 0
    end)
  end,
})

return zhongyong
