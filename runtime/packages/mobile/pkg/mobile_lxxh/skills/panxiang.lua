local panxiang = fk.CreateSkill {
  name = "panxiang",
}

Fk:loadTranslationTable{
  ["panxiang"] = "蹒襄",
  [":panxiang"] = "当一名角色受到伤害时，你可以选择一项（不能选择上次对该角色发动时选择的选项）：1.令此伤害-1，然后伤害来源摸两张牌；"..
  "2.令此伤害+1，然后其摸三张牌。",

  ["#panxiang-invoke"] = "蹒襄：你可以选择一项：",
  ["panxiang1"] = "伤害-1",
  ["panxiang1-from"] = "伤害-1，%src摸两张牌",
  ["panxiang2"] = "伤害+1，其摸三张牌",
  ["@panxiang"] = "蹒襄",
  ["mkpanxiang1"] = "－",
  ["mkpanxiang2"] = "＋",

  ["$panxiang1"] = "殿下当以国事为重，奈何效匹夫之孝乎？",
  ["$panxiang2"] = "诸卿当早拜嗣君，以镇海内，而但哭邪？",
  ["$panxiang3"] = "身负托孤之重，但坐论清谈，此亦可乎？",
  ["$panxiang4"] = "老臣受命督军，自竭拒吴蜀于疆外。",
}

panxiang:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(panxiang.name)
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"panxiang2"}
    if data.from and not data.from.dead then
      table.insert(all_choices, 1, "panxiang1-from:" .. data.from.id)
    else
      table.insert(all_choices, 1, "panxiang1")
    end
    table.insert(all_choices, "Cancel")
    local choices = table.simpleClone(all_choices)
    local mark = target:getMark("@panxiang")
    if type(mark) == "string" then
      local n = string.match(mark, "mkpanxiang(%d)")
      if n then table.remove(choices, n) end
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = panxiang.name,
      prompt = "#panxiang-invoke::"..target.id,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice, extra_data = table.indexOf(all_choices, choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "panxiang_"..target.id, event:getCostData(self))
    room:setPlayerMark(target, "@panxiang", "mkpanxiang" .. event:getCostData(self).extra_data)
    room:notifySkillInvoked(player, panxiang.name, "support")
    room:doIndicate(player, {target})
    if event:getCostData(self).choice == "panxiang2" then
      player:broadcastSkillInvoke(panxiang.name, math.random(1, 2))
      data:changeDamage(1)
      if not target.dead then
        room:drawCards(target, 3, panxiang.name)
      end
    else
      player:broadcastSkillInvoke(panxiang.name, math.random(3, 4))
      data:changeDamage(-1)
      if data.from and not data.from.dead then
        data.from:drawCards(2, panxiang.name)
      end
    end
  end,
})

return panxiang
