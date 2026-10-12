local luanchou = fk.CreateSkill{
  name = "os__luanchou",
  related_skills = { "os__gonghuan" },
}

Fk:loadTranslationTable{
  ["os__luanchou"] = "鸾俦",
  [":os__luanchou"] = "每轮开始时，你可以选择两名角色视为拥有〖共患〗直到你下次发动此技能。",

  ["#os__luanchou-ask"] = "鸾俦：你可以选择两名角色视为拥有〖共患〗直到你下次发动此技能",
  ["@[list]os__luanchou"] = "鸾俦",

  ["$os__luanchou1"] = "若成此事，百姓必夹道相庆。",
  ["$os__luanchou2"] = "之子于归，宜其室家。",
}

luanchou:addEffect(fk.TurnStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(luanchou.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 2,
      max_num = 2,
      cancelable = true,
      skill_name = luanchou.name,
      prompt = "#os__luanchou-ask",
    })
    if #tos > 1 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    local old = player:getMark("@[list]os__luanchou")
    if old ~= 0 then
      for _, t in ipairs(old) do
        room:handleAddLoseSkills(t, "-os__gonghuan", luanchou.name)
      end
    end
    for _, t in ipairs(tos) do
      room:handleAddLoseSkills(t, "os__gonghuan", luanchou.name)
    end
    room:setPlayerMark(player, "@[list]os__luanchou", tos)
  end,
})

return luanchou
