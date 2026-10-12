local os__huantu = fk.CreateSkill {
  name = "os__huantu",
}

Fk:loadTranslationTable{
  ["os__huantu"] = "缓图",
  [":os__huantu"] = "每轮限一次，其他角色摸牌阶段开始前，你可以交给其一张牌，令其跳过摸牌阶段，若如此做，本回合结束阶段你选择一项："..
  "1.令其回复1点体力并摸两张牌；2.你摸三张牌并交给其两张手牌。若其本回合未造成伤害且其在你攻击范围内，你可以执行另一项。",

  ["#os__huantu-invoke"] = "缓图：你可以交给 %dest 一张牌令其跳过摸牌阶段，本回合结束阶段其摸牌",
  ["os__huantu1"] = "%dest回复1点体力并摸两张牌",
  ["os__huantu2"] = "你摸三张牌，然后交给%dest两张手牌",
  ["#os__huantu-give"] = "缓图：交给 %dest 两张手牌",

  ["$os__huantu1"] = "得此虚物，谓承天命而王之，此天下未之有也！",
  ["$os__huantu2"] = "此印表为祥瑞，实为不祥，愿主勿议称王之事。",
}

os__huantu:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(os__huantu.name) and
      data.phase == Player.Draw and
      not data.skipped and
      not player:isNude() and
      player:usedSkillTimes(os__huantu.name, Player.HistoryRound) == 0 and
      player ~= target
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__huantu.name,
        prompt = "#os__huantu-invoke::" .. target.id,
      }
    )
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, os__huantu.name, nil, false, player)
    data.skipped = true
  end,
})

os__huantu:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:isAlive() and
      player:usedSkillTimes(os__huantu.name, Player.HistoryTurn) > 0 and
      target.phase == Player.Finish and
      target:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = os__huantu.name
    local room = player.room
    room:doIndicate(player, { target })

    local choices = { "os__huantu1::" .. target.id, "os__huantu2::" .. target.id }
    local choice = room:askToChoice(player, { choices = choices, skill_name = skillName })

    local huantu1 = function ()
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
    end
    local huantu2 = function ()
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
              prompt = "#os__huantu-give::" .. target.id,
            }
          )
        end
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, skillName, nil, false, player)
      end
    end

    if choice[11] == "1" then
      huantu1()
    else
      huantu2()
    end
    if player:inMyAttackRange(target) and #room.logic:getActualDamageEvents(1, function (e)
      return e.data.from == target
    end, Player.HistoryTurn) == 0 then
      table.removeOne(choices, choice)
      table.insert(choices, "Cancel")
      choice = room:askToChoice(player, { choices = choices, skill_name = skillName })
      if choice:startsWith("os__huantu1") then
        huantu1()
      elseif choice:startsWith("os__huantu2") then
        huantu2()
      end
    end
  end,
})

return os__huantu
