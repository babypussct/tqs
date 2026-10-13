local zhuwei = fk.CreateSkill {
  name = "jiange__zhuwei",
}

Fk:loadTranslationTable{
  ["jiange__zhuwei"] = "筑围",
  [":jiange__zhuwei"] = "当你的判定牌生效后，若为【杀】或伤害类锦囊牌，你可以获得之，并令当前回合角色本回合出牌阶段使用【杀】次数和手牌上限+1。",

  ["#jiange__zhuwei1-invoke"] = "筑围：是否获得判定牌%arg？",
  ["#jiange__zhuwei2-invoke"] = "筑围：是否获得判定牌%arg，并令 %dest 本回合使用【杀】次数上限和手牌上限+1？",
}

zhuwei:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuwei.name) and
      data.card and data.card.is_damage_card and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local prompt = "#jiange__zhuwei1-invoke:::"..data.card:toLogString()
    event:setCostData(self, nil)
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event then
      local to = turn_event.data.who
      if not to.dead then
        prompt = "#jiange__zhuwei2-invoke::"..to.id..":"..data.card:toLogString()
        event:setCostData(self, {tos = {to}})
      end
    end
    return room:askToSkillInvoke(player, {
      skill_name = zhuwei.name,
      prompt = prompt,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) then
      room:addPlayerMark(room.current, MarkEnum.SlashResidue.."-turn", 1)
      room:addPlayerMark(room.current, MarkEnum.AddMaxCardsInTurn, 1)
    end
    room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, zhuwei.name, nil, true, player)
  end,
})

return zhuwei
