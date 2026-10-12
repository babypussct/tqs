local gongxiu = fk.CreateSkill{
  name = "ty_heg__gongxiu",
}
gongxiu:addEffect(fk.DrawNCards, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongxiu.name) and data.n > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = gongxiu.name,
      prompt = "#ty_heg__gongxiu_" .. player:getMark("ty_heg__gongxiu") .. "-ask:::" .. player.maxHp
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.n = data.n - 1
    local choices = {}
    if player:getMark("ty_heg__gongxiu") ~= 1 then
      table.insert(choices, "ty_heg__gongxiu_draw:::" .. player.maxHp)
    end
    if player:getMark("ty_heg__gongxiu") ~= 2 then
      table.insert(choices, "ty_heg__gongxiu_discard:::" .. player.maxHp)
    end
    local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = gongxiu.name,
        prompt = "#ty_heg__gongxiu-choice",
      })
    local tos
    if choice:startsWith("ty_heg__gongxiu_draw") then
      room:setPlayerMark(player, "ty_heg__gongxiu", 1)
      tos = room:askToChoosePlayers(player,{
        targets = room.alive_players, min_num = 1, max_num = player.maxHp,
        propmt = "#ty_heg__gongxiu_draw-choose:::" .. player.maxHp,
        skill_name = gongxiu.name, cancelable = false
      })
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead then
          p:drawCards(1, gongxiu.name)
        end
      end
    else
      room:setPlayerMark(player, "ty_heg__gongxiu", 2)
      tos = room:askToChoosePlayers(player,{
        targets = room.alive_players, min_num = 1, max_num = player.maxHp,
        propmt = "#ty_heg__gongxiu_discard-choose:::" .. player.maxHp,
        skill_name = gongxiu.name, cancelable = false
      })
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead and not p:isNude() then
          room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = gongxiu.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__gongxiu"] = "共修",
  [":ty_heg__gongxiu"] = "摸牌阶段，你可少摸一张牌，然后选择一项：1.令至多X名角色各摸一张牌；"..
    "2.令至多X名角色各弃置一张牌。（X为你的体力上限，不能连续选择同一项）",

  ["#ty_heg__gongxiu-choice"] = "共修：选择令角色摸牌或弃牌",
  ["#ty_heg__gongxiu_0-ask"] = "是否发动 共修，令至多%arg名角色各摸一张牌或各弃置一张牌",
  ["#ty_heg__gongxiu_1-ask"] = "是否发动 共修，令至多%arg名角色各弃置一张牌",
  ["#ty_heg__gongxiu_2-ask"] = "是否发动 共修，令至多%arg名角色各摸一张牌",
  ["ty_heg__gongxiu_draw"] = "令至多%arg名角色各摸一张牌",
  ["ty_heg__gongxiu_discard"] = "令至多%arg名角色各弃置一张牌",

  ["#ty_heg__gongxiu_draw-choose"] = "共修：选择至多%arg名角色各摸一张牌",
  ["#ty_heg__gongxiu_discard-choose"] = "共修：选择至多%arg名角色各弃置一张牌",

  ["$ty_heg__gongxiu1"] = "福祸与共，业山可移。",
  ["$ty_heg__gongxiu2"] = "修行退智，遂之道也。",
}

return gongxiu
