local beixing = fk.CreateSkill{
  name = "os__beixing",
}

Fk:loadTranslationTable{
  ["os__beixing"] = "狈行",
  [":os__beixing"] = "每轮限一次，其他角色的出牌阶段结束时，若其本回合未造成过伤害，你可以展示其所有手牌，" ..
    "然后弃置其一张手牌，<a href='os__override'>凌越·体力</a>：你可以令一名因〖毁誉〗代替成为过伤害来源的角色获得其一张手牌。",

  ["#os__beixing-invoke"] = "你可发动 狈行，展示 %dest 的手牌并弃置其一张手牌",
  ["#os__beixing-discard"] = "狈行：弃置 %dest 的一张手牌",
  ["#os__huiyu_override"] = "狈行：你可令一名角色获得 %dest 的一张手牌",
  ["#os__beixing-obtain"] = "狈行：获得 %dest 的一张手牌",

  ["$os__beixing1"] = "蔡氏帐下，敢有逆鳞者当诛！",
  ["$os__beixing2"] = "荆襄之地，容不得一根异刺！",
}

beixing:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(beixing.name) and target ~= player and
      target.phase == Player.Play and player:usedSkillTimes(beixing.name, Player.HistoryRound) == 0 and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == target
      end, Player.HistoryTurn) == 0 and not target:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = beixing.name,
      prompt = "#os__beixing-invoke::" .. target.id
    }) then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = target:getCardIds("h")
    if #cards == 0 then return end
    target:showCards(cards)
    if target.dead or player.dead or target:isKongcheng() then return end
    local card = room:askToChooseCard(player, {
      min_num = 1,
      max_num = 1,
      target = target,
      flag = "h",
      prompt = "#os__beixing-discard::" .. target.id,
      skill_name = beixing.name,
      cancelable = false,
    })
    room:throwCard(card, beixing.name, target, player)
    if player.hp > target.hp and target:isAlive() and not target:isKongcheng() then
      local tos = player:getTableMark("_os__huiyu_substitutes")
      if #tos > 0 then
        local tos_player = room:askToChoosePlayers(
          player,
          {
            targets = table.map(tos, Util.Id2PlayerMapper),
            min_num = 1,
            max_num = 1,
            prompt = "#os__huiyu_override::" .. target.id,
            skill_name = beixing.name,
            cancelable = true,
          }
        )
        if #tos_player > 0 then
          card = room:askToChooseCard(tos_player[1], {
            min_num = 1,
            max_num = 1,
            target = target,
            flag = "h",
            prompt = "#os__beixing-obtain::" .. target.id,
            skill_name = beixing.name,
            cancelable = false,
          })
          room:obtainCard(tos_player[1], card, false, fk.ReasonPrey, player, beixing.name)
        end
      end
    end
  end
})

return beixing
