local huantu = fk.CreateSkill {
  name = "huantu",
}

Fk:loadTranslationTable{
  ["huantu"] = "缓图",
  [":huantu"] = "每轮限一次，你攻击范围内一名其他角色摸牌阶段开始前，你可以交给其一张牌，令其跳过摸牌阶段，若如此做，本回合结束阶段你选择一项："..
  "1.令其回复1点体力并摸两张牌；2.你摸三张牌并交给其两张手牌。",

  ["#huantu-invoke"] = "缓图：你可以交给 %dest 一张牌令其跳过摸牌阶段，本回合结束阶段其摸牌",
  ["huantu1"] = "%dest回复1点体力并摸两张牌",
  ["huantu2"] = "你摸三张牌，然后交给%dest两张手牌",
  ["#huantu-give"] = "缓图：交给 %dest 两张手牌",

  ["$huantu1"] = "今群雄蜂起，主公宜外收内敛，勿为祸先。",
  ["$huantu2"] = "昔陈胜之事，足为今日之师，望主公熟虑。",
}

huantu:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(huantu.name) and
      player:inMyAttackRange(target) and
      data.phase == Player.Draw and
      not data.skipped and
      not player:isNude() and
      player:usedSkillTimes(huantu.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = huantu.name,
        prompt = "#huantu-invoke::" .. target.id,
      }
    )
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self), Card.PlayerHand, target, fk.ReasonGive, huantu.name, nil, false, player)
    data.skipped = true
  end,
})

huantu:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:isAlive() and
      player:usedSkillTimes(huantu.name, Player.HistoryTurn) > 0 and
      target.phase == Player.Finish and
      target:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huantu.name
    local room = player.room
    room:doIndicate(player, { target })

    local choices = { "huantu1::" .. target.id, "huantu2::" .. target.id }
    local choice = room:askToChoice(player, { choices = choices, skill_name = skillName })

    if choice[7] == "1" then
      if target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = skillName,
        })
      end
      if target:isAlive() then
        target:drawCards(2, skillName)
      end
    else
      player:drawCards(3, skillName)
      if not player:isKongcheng() and target:isAlive() then
        local cards = player:getCardIds("h")
        if #cards > 2 then
          cards = room:askToCards(
            player,
            {
              min_num = 2,
              max_num = 2,
              skill_name = skillName,
              cancelable = false,
              prompt = "#huantu-give::" .. target.id,
            }
          )
        end
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, skillName, nil, false, player)
      end
    end
  end,
})

return huantu
