local zhengjian = fk.CreateSkill {
  name = "zhengjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhengjian"] = "诤荐",
  [":zhengjian"] = "锁定技，结束阶段，你令一名角色获得“诤荐”标记，然后其于你的下个回合开始时摸X张牌并移去“诤荐”标记（X为其此期间使用或打出牌的数量且"..
  "至多为其体力上限且至多为5）。",

  ["@zhengjian"] = "诤荐",
  ["#zhengjian-choose"] = "选择“诤荐”的目标",

  ["$zhengjian1"] = "此人有雄猛逸才，还请明公观之。",
  ["$zhengjian2"] = "若明公得此人才，定当如虎添翼。",
}

zhengjian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(zhengjian.name) and
      player.phase == Player.Finish and
      table.find(player.room.alive_players, function(p)
        return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room.alive_players, function(p)
      return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0
    end)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhengjian-choose",
        skill_name = zhengjian.name,
        cancelable = false,
      }
    )

    room:setPlayerMark(tos[1], "@zhengjian", "0")
  end,
})

zhengjian:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(zhengjian.name) and
      table.find(player.room.alive_players, function(p)
        return not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      local mark = type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") or 0
      room:setPlayerMark(p, "@zhengjian", 0)
      if mark > 0 then
        local x = math.min(mark, p.maxHp, 5)
        p:drawCards(x, zhengjian.name)
      end
    end
  end,
})

local zhengjianCountSpec = {
  can_refresh = function (self, event, target, player, data)
    return target == player and not (type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") == 0)
  end,
  on_refresh = function (self, event, target, player, data)
    local mark = type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") or 0
    player.room:setPlayerMark(player, "@zhengjian", math.min(5, mark + 1))
  end,
}

zhengjian:addEffect(fk.CardUsing, zhengjianCountSpec)

zhengjian:addEffect(fk.CardResponding, zhengjianCountSpec)

zhengjian:addEffect(fk.Deathed, {
  can_refresh = function (self, event, target, player, data)
    return not table.find(player.room.alive_players, function(p) return p:hasSkill(zhengjian.name, true) end)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@zhengjian", 0)
    end
  end,
})

return zhengjian
