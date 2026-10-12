
local boyan = fk.CreateSkill{
  name = "ty_heg__boyan",
}

Fk:loadTranslationTable{
  ["ty_heg__boyan"] = "驳言",
  [":ty_heg__boyan"] = "出牌阶段限一次，你可以选择一名其他角色，其将手牌摸至其体力上限，其本回合不能使用或打出手牌。<br>"..
  "<a href='ty_heg_zongheng'>纵横</a>：删去〖驳言〗描述中的“其将手牌摸至体力上限”。",

  ["ty_heg__boyan_mn_ask"] = "令%dest获得〖驳言（纵横）〗直到其下回合结束",

  ["@@ty_heg__boyan-turn"] = "驳言",
  ["@@ty_heg__boyan_manoeuvre"] = "驳言 纵横",

  ["$ty_heg__boyan1"] = "黑白颠倒，汝言谬矣！",
  ["$ty_heg__boyan2"] = "魏王高论，实为无知之言。",
}

boyan:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(boyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = target.maxHp - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, boyan.name)
    end
    room:setPlayerMark(target, "@@ty_heg__boyan-turn", 1)
    local choices = {"ty_heg__boyan_mn_ask::" .. target.id, "Cancel"}
    if room:askToChoice(player, {
      choices = choices,
      skill_name = boyan.name
    }) ~= "Cancel" then
      room:setPlayerMark(target, "@@ty_heg__boyan_manoeuvre", 1)
      room:handleAddLoseSkills(target, "ty_heg__boyan_manoeuvre", nil)
    end
  end,
})
boyan:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@ty_heg__boyan-turn") == 0 then return false end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@ty_heg__boyan-turn") == 0 then return false end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
  end,
})

return boyan
