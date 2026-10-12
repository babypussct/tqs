local mibei = fk.CreateSkill {
  name = "os__mibei",
  tags = { Skill.Quest },
  related_skills = { "os__mouli" },
}

Fk:loadTranslationTable{
  ["os__mibei"] = "秘备",
  [":os__mibei"] = "<a href='os__quest'>使命技</a>，使用每种类别的牌各至少两张。<br>"..
  "⬤　成功：你获得〖谋立〗。<br>"..
  "⬤　完成前：出牌阶段结束时，若你本回合未使用过牌，则你此回合手牌上限-1并重置〖秘备〗。",

  ["os__quest"] = "#\"<b>使命技(国际服)</b>\"：在成功后失效，完成前有一定的惩罚。",
  ["@os__mibei"] = "秘备",

  ["$os__mibei1"] = "密为之备，不可有失。",
  ["$os__mibei2"] = "事以密成，语以泄败！",
}

mibei:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mibei.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@os__mibei")
    if #mark == 0 then
      mark = { 0, 0, 0 }
    end
    if data.card.type == Card.TypeBasic then
      mark[1] = mark[1] + 1
    elseif data.card.type == Card.TypeTrick then
      mark[2] = mark[2] + 1
    elseif data.card.type == Card.TypeEquip then
      mark[3] = mark[3] + 1
    end
    room:setPlayerMark(player, "@os__mibei", mark)
    if table.every(mark, function (i)
      return i > 1
    end) then
      room:updateQuestSkillState(player, mibei.name, true) -- 为了有那个白底……
      room:updateQuestSkillState(player, mibei.name, false)
      room:handleAddLoseSkills(player, "os__mouli")
      room:setPlayerMark(player, "@os__mibei", 0)
      room:invalidateSkill(player, mibei.name)
    end
  end,
})

mibei:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(mibei.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
    room:setPlayerMark(player, "@os__mibei", {0, 0, 0})
    room:updateQuestSkillState(player, mibei.name, true)
  end,
})

mibei:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@os__mibei", 0)
end)

return mibei
