local mobileJimeng = fk.CreateSkill {
  name = "mobile__jimeng",
}

Fk:loadTranslationTable{
  ["mobile__jimeng"] = "急盟",
  [":mobile__jimeng"] = "出牌阶段开始时，你可以获得一名其他角色的一张牌，然后你交给该角色X张牌（X为你的体力值）。",

  ["#mobile__jimeng-choose"] = "急盟：你可以获得一名其他角色的一张牌，然后交给其 %arg 张牌",
  ["#mobile__jimeng-give"] = "急盟：交给 %dest %arg张牌",

  ["$mobile__jimeng1"] = "曹魏已成鲸吞之势，还望连横抗之。",
  ["$mobile__jimeng2"] = "主上幼弱，吾愿往重修吴好。",
}

mobileJimeng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mobileJimeng.name) and
      player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#mobile__jimeng-choose:::" .. player.hp,
          skill_name = mobileJimeng.name,
        }
      )
      if #tos > 0 then
        event:setCostData(self, tos[1])
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileJimeng.name
    local room = player.room
    local to = event:getCostData(self)
    local id = room:askToChooseCard(player, { target = to, flag = "he", skill_name = skillName })

    room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)

    if not player:isAlive() or player:isNude() or player.hp < 1 then return false end
    local cards = room:askToCards(
      player,
      {
        min_num = player.hp,
        max_num = player.hp,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
        prompt = "#mobile__jimeng-give::" .. to.id .. ":" .. player.hp,
      }
    )
    room:obtainCard(to, cards, false, fk.ReasonGive, player, skillName)
  end,
})

return mobileJimeng
