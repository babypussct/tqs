
local zongkui = fk.CreateSkill {
  name = "zongkui"
}

Fk:loadTranslationTable{
  ["zongkui"] = "纵傀",
  [":zongkui"] = "回合开始时，你可以令一名没有“傀”标记的其他角色获得“傀”。"..
  "每轮开始时，体力值最少且没有“傀”的一名其他角色获得“傀”。",

  ["@@puppet"] = "傀",
  ["#zongkui-choose"] = "纵傀：选择一名其他角色，令其获得一枚“傀”",

  ["$zongkui1"] = "准备好听候女王的差遣了吗？",
  ["$zongkui2"] = "契约已定。",
}

zongkui:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongkui.name) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@puppet") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@puppet") == 0
      end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zongkui-choose",
      skill_name = zongkui.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self).tos[1], "@@puppet", 1)
  end,
})

zongkui:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongkui.name) then
      for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
        if p:getMark("@@puppet") == 0 and
          table.every(player.room:getOtherPlayers(player, false), function (q)
            return p.hp <= q.hp
          end) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getMark("@@puppet") == 0 and
        table.every(room:getOtherPlayers(player, false), function (q)
          return p.hp <= q.hp
        end)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zongkui-choose",
      skill_name = zongkui.name,
      cancelable = false,
    })[1]
    room:addPlayerMark(to, "@@puppet", 1)
  end,
})

return zongkui
