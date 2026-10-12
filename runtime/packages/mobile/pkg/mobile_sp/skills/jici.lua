local jici = fk.CreateSkill{
  name = "jici",
}

Fk:loadTranslationTable{
  ["jici"] = "激词",
  [":jici"] = "当你发动〖鼓舌〗拼点牌亮出后，若点数小于X，你可以令点数+X；若点数等于X，你可以令你本阶段〖鼓舌〗可发动次数+1"..
  "（X为你“饶舌”标记的数量）。",

  ["$jici1"] = "谅尔等腐草之荧光，如何比得上天空之皓月？",
  ["$jici2"] = "你……诸葛村夫，你敢！",
}

jici:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jici.name) and
      player == data.from and data.reason == "gushe" and
      data.fromCard and data.fromCard.number <= player:getMark("@raoshe")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.fromCard.number < player:getMark("@raoshe") then
      room:changePindianNumber(data, player, player:getMark("@raoshe"), jici.name)
    else
      player:setSkillUseHistory("gushe", 0, Player.HistoryPhase)
    end
  end,
})

return jici
