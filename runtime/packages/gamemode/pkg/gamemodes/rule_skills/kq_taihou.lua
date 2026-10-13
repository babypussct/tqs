local taihou = fk.CreateSkill {
  name = "#kq__taihou",
}

Fk:loadTranslationTable{
  ["#kq__taihou"] = "始称太后",
  [":#kq__taihou"] = "游戏开始时，所有女性角色的体力值和体力上限+1；若场上有芈月，每名男性角色的回合开始时，其选择一项："..
  "1.令芈月回复1点体力；2.令芈月摸一张牌。",

  ["kq__taihou_recover"] = "%src回复1点体力",
  ["kq__taihou_draw"] = "%src摸一张牌",
}

taihou:addEffect(fk.GameStart, {
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isFemale() then
        p.maxHp = p.maxHp + 1
        p.hp = p.hp + 1
        room:broadcastProperty(p, "maxHp")
        room:broadcastProperty(p, "hp")
      end
    end
  end,
})

taihou:addEffect(fk.TurnStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:isMale() and
      table.find(player.room.alive_players, function (p)
        return Fk.generals[p.general].trueName == "miyue" or (Fk.generals[p.deputyGeneral] or {}).trueName == "miyue"
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local miyue = table.find(player.room.alive_players, function (p)
      return Fk.generals[p.general].trueName == "miyue" or (Fk.generals[p.deputyGeneral] or {}).trueName == "miyue"
    end)
    if miyue == nil or miyue.dead then return end
    miyue:broadcastSkillInvoke("qin__taihou")
    miyue:chat("$qin__taihou")
    local choices = {"kq__taihou_draw:"..miyue.id}
    if miyue:isWounded() then
      table.insert(choices, "kq__taihou_recover:"..miyue.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = taihou.name,
    })
    if choice:startsWith("kq__taihou_draw") then
      miyue:drawCards(1, taihou.name)
    else
      room:recover{
        who = miyue,
        num = 1,
        recoverBy = player,
        skillName = taihou.name,
      }
    end
  end,
})

return taihou
