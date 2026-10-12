local wangjingm = fk.CreateSkill {
  name = "wangjingm",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wangjingm"] = "往京",
  [":wangjingm"] = "锁定技，当你发动〖集兵〗使用或打出一张“兵”时，若对方是场上体力值最高的角色，你摸一张牌。",

  ["$wangjingm1"] = "联络朝中中常侍，共抗朝廷不义师！",
  ["$wangjingm2"] = "往来京城，与众常侍密谋举事！",
}

local wangjingmOnUse = function(self, event, target, player, data)
  player:drawCards(1, wangjingm.name)
end

wangjingm:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if
      target == player and
      player:hasSkill(wangjingm.name) and
      table.find(data.card.skillNames, function(name) return string.find(name, "jibing") end)
    then
      local to
      if data.card.trueName == "slash" then
        to = data.tos[1]
      elseif data.card.name == "jink" then
        if data.responseToEvent then
          to = data.responseToEvent.from  --jink
        end
      end
      return to and table.every(player.room.alive_players, function(p) return to.hp >= p.hp end)
    end
  end,
  on_use = wangjingmOnUse,
})

wangjingm:addEffect(fk.CardResponding, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if
      target == player and
      player:hasSkill(wangjingm.name) and
      table.find(data.card.skillNames, function(name) return string.find(name, "jibing") end)
    then
      local to
      if data.responseToEvent then
        if data.responseToEvent.from == player then
          to = data.responseToEvent.to  --duel used by self
        else
          to = data.responseToEvent.from  --savsavage_assault, archery_attack, passive duel
        end
      end
      return to and table.every(player.room.alive_players, function(p) return to.hp >= p.hp end)
    end
  end,
  on_use = wangjingmOnUse,
})

return wangjingm
