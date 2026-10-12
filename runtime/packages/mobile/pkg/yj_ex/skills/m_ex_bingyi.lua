local mExBingyi = fk.CreateSkill {
  name = "m_ex__bingyi"
}

Fk:loadTranslationTable{
  ["m_ex__bingyi"] = "秉壹",
  [":m_ex__bingyi"] = "结束阶段，你可以展示所有手牌，若均为同一颜色或类别，则你令至多X名角色各摸一张牌（X为你的手牌数）。",

  ["#m_ex__bingyi-choose"] = "秉壹：请选择至多%arg名角色各摸一张牌",

  ["$m_ex__bingyi1"] = "秉直进谏，勿藏私心。",
  ["$m_ex__bingyi2"] = "秉公守一，不负圣恩。",
}

mExBingyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mExBingyi.name) and
      player.phase == Player.Finish and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mExBingyi.name
    local room = player.room
    local cards = player:getCardIds("h")
    if #cards == 0 then
      return false
    end

    player:showCards(cards)
    if not player:isAlive() or player:isKongcheng() then
      return false
    end

    if
      table.every(cards, function (id)
        return Fk:getCardById(id):compareColorWith(Fk:getCardById(cards[1]))
      end) or
      table.every(cards, function (id)
        return Fk:getCardById(id).type == Fk:getCardById(cards[1]).type
      end)
    then
      local tos = room:askToChoosePlayers(
        player,
        {
          skill_name = skillName,
          min_num = 1,
          max_num = #cards,
          targets = room:getAlivePlayers(false),
          prompt = "#m_ex__bingyi-choose:::" .. #cards,
          cancelable = false,
        }
      )
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if p:isAlive() then
            p:drawCards(1, skillName)
          end
        end
      end
    end
  end,
})

return mExBingyi
