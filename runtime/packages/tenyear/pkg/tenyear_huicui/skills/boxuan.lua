local boxuan = fk.CreateSkill {
  name = "boxuan",
}

Fk:loadTranslationTable{
  ["boxuan"] = "博玄",
  [":boxuan"] = "当你使用指定其他角色为目标的不为延时类锦囊牌的手牌结算完毕后，你可以展示牌堆底三张牌，若其中有牌与你使用的牌：<br>"..
    "牌名字数相同，你摸一张牌；<br>花色相同，你可以弃置一名其他角色的一张牌；<br>类别相同，你可以使用一张展示的牌。",

  ["#boxuan-discard"] = "博玄：你可以弃置一名其他角色的一张牌",
  ["#boxuan-use"] = "博玄：你可以使用其中一张牌",
  ["#boxuan-put"] = "博玄：是否将%arg置于牌堆底？",

  ["$boxuan1"] = "怪力乱神不可语，死生祸福不可预。",
  ["$boxuan2"] = "日月入我怀，此志通天下。",
}

boxuan:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.sub_type ~= Card.SubtypeDelayedTrick and
      player:hasSkill(boxuan.name) and
      data:isUsingHandcard(player) and
      (
        player:usedSkillTimes("guilin", Player.HistoryGame) > 0 and
        #data.tos > 0 or
        table.find(data.tos, function (p)
          return p ~= player
        end)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    room:showCards(cards)
    --FIXME: 展示后应当置入处理区，但是由于不想桌面上出现两倍的牌，暂且不做
    if table.find(cards, function(id)
      return data.card:getNameLength() == Fk:getCardById(id):getNameLength()
    end) then
      player:drawCards(1, boxuan.name)
      if player.dead then return end
    end
    if table.find(cards, function(id)
      return data.card:compareSuitWith(Fk:getCardById(id))
    end) then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          skill_name = boxuan.name,
          min_num = 1,
          max_num = 1,
          targets = targets,
          prompt = "#boxuan-discard",
          cancelable = true,
        })
        if #to > 0 then
          local id = room:askToChooseCard(player, {
            target = to[1],
            flag = "he",
            skill_name = boxuan.name,
          })
          room:throwCard(id, boxuan.name, to[1], player)
          if player.dead then return end
        end
      end
    end
    if table.find(cards, function(id)
      return data.card.type == Fk:getCardById(id).type
    end) then
      room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = boxuan.name,
        prompt = "#boxuan-use",
        extra_data = {
          bypass_times = false,
          extraUse = false,
          expand_pile = cards,
        },
      })
    end
  end,
})

boxuan:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return boxuan
