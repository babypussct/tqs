
local weidai = fk.CreateSkill{
  name = "weidai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weidai"] = "魏代",
  [":weidai"] = "锁定技，当魏势力角色对你使用牌后，你增加1点体力上限，若因此你的体力上限全场最大，你将体力上限调整至体力值，"..
  "并摸失去体力上限张牌。若摸牌数大于等于存活角色数，你将一名角色势力改为魏。",

  ["#weidai-choose"] = "魏代：将一名角色势力改为魏",

  ["$weidai1"] = "今受汉禅，自为魏真祖！",
  ["$weidai2"] = "朕没纂汉，这是魏代，大魏代！",
}

weidai:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weidai.name) and
      target.kingdom == "wei" and table.contains(data.tos, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead or not player:isWounded() then return end
    if table.every(room.alive_players, function (p)
      return player.maxHp >= p.hp
    end) then
      local n = player.maxHp - player.hp
      room:changeMaxHp(player, -n)
      if player.dead then return end
      player:drawCards(n, weidai.name)
      if player.dead then return end
      if n >= #room.alive_players then
        local targets = table.filter(room.alive_players, function (p)
          return p.kingdom ~= "wei"
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#weidai-choose",
            skill_name = weidai.name,
            cancelable = false,
          })[1]
          room:changeKingdom(to, "wei")
        end
      end
    end
  end,
})

return weidai
