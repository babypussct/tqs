local mibei = fk.CreateSkill {
  name = "mibei",
  tags = { Skill.Quest },
  related_skills = { "mouli" },
}

Fk:loadTranslationTable{
  ["mibei"] = "秘备",
  [":mibei"] = "使命技，<br>"..
  "⬤　成功：当你使用牌结算后，若你拥有每种牌类别的“备”各不少于两个，你从牌堆获得每种类别的牌各一张，然后获得技能〖谋立〗。<br>"..
  "⬤　失败：弃牌阶段结束时，若此时和本回合准备阶段你均没有“备”，你减1点体力上限且使命失败。",

  ["$mibei1"] = "密为之备，不可有失。",
  ["$mibei2"] = "事以密成，语以泄败！",
}

mibei:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(mibei.name) and
      #player:getTableMark("@$wangling_bei") > 5 then
      local nums = {0, 0, 0}
      for _, name in ipairs(player:getMark("@$wangling_bei")) do
        local type = Fk:cloneCard(name).type
        nums[type] = nums[type] + 1
      end
      return table.every(nums, function(num)
        return num > 1
      end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mibei.name, 1)
    room:notifySkillInvoked(player, mibei.name, "drawcard")
    room:updateQuestSkillState(player, mibei.name, false)
    room:invalidateSkill(player, mibei.name)
    local types = {"basic", "trick", "equip"}
    local cards = {}
    while #types > 0 do
      local pattern = room:tableRandomPick(types)
      table.removeOne(types, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..pattern, 1, "drawPile"))
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, mibei.name, nil, false, player)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "mouli")
    end
  end,
})
mibei:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mibei.name) and player.phase == Player.Discard and
      player:getMark("@$wangling_bei") == 0 and player:getMark("mibei_fail-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mibei.name, 2)
    room:notifySkillInvoked(player, mibei.name, "negative")
    room:updateQuestSkillState(player, mibei.name, true)
    room:invalidateSkill(player, mibei.name)
    room:changeMaxHp(player, -1)
  end,
})
mibei:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(mibei.name, true) and player.phase == Player.Start and
      player:getMark("@$wangling_bei") == 0 and not player:getQuestSkillState(mibei.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "mibei_fail-turn", 1)
  end,
})

return mibei
