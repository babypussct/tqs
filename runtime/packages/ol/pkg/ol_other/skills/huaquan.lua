local huaquan = fk.CreateSkill {
  name = "huaquan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huaquan"] = "花拳",
  [":huaquan"] = "锁定技，当你使用牌指定其他角色为目标后，你为此牌秘密选择一个效果：重拳，令此牌伤害基数+1；" ..
  "轻拳，此牌使用结算结束后你摸一张牌。然后目标中的所有其他角色同时猜测你选择的效果。",

  ["huquan_zhongquan"] = "重拳：加伤",
  ["huaquan_qingquan"] = "轻拳：摸牌",
  ["#huaquan-choose"] = "花拳：请为此牌选择一个效果",
  ["#huaquan-guess"] = "花拳：请猜测 %src 为 %arg 选择的效果",

  ["#HuaQuanChoice"] = "%from猜测“花拳”的效果为%arg，%from%arg2",
  ["huaquan_right"] = "猜对",
  ["huaquan_wrong"] = "猜错",

  ["$huaquan1"] = "避无可避，拳从八方来！",
  ["$huaquan2"] = "轻拳打脸，重拳取命！",
}

huaquan:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.firstTarget and
      player:hasSkill(huaquan.name) and
      table.find(data.use.tos, function(p) return p ~= player end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huaquan.name
    local room = player.room

    local choice = room:askToChoice(
      player,
      {
        choices = { "huquan_zhongquan", "huaquan_qingquan" },
        skill_name = skillName,
        prompt = "#huaquan-choose",
      }
    )

    if choice == "huquan_zhongquan" then
      data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.huaquanUser = player
    end

    local others = table.filter(
      data.use.tos,
      function(p)
        return p ~= player and p:isAlive()
      end
    )

    if #others == 0 then
      return false
    end

    local result = room:askToJointChoice(
      player,
      {
        players = others,
        choices = { "huquan_zhongquan", "huaquan_qingquan" },
        skill_name = skillName,
        prompt = "#huaquan-guess:" .. player.id .. "::" .. data.card:toLogString(),
      }
    )

    for _, p in ipairs(others) do
      room:sendLog{
        type = "#HuaQuanChoice",
        from = p.id,
        arg = result[p],
        arg2 = result[p] == choice and "huaquan_right" or "huaquan_wrong",
        toast = true,
      }
    end

    if not player:hasSkill("sanou") then
      return false
    end

    for p, chosen in pairs(result) do
      if chosen ~= choice then
        player:drawCards(1, "sanou")
        room:addPlayerMark(p, "@sanou_knockout")
        if p:getMark("@sanou_knockout") >= 3 then
          room:setPlayerMark(p, "@sanou_knockout", 0)
          if p:getMark("@sanou_countdown") == 0 then
            room:setPlayerMark(p, "@sanou_countdown", 10)
          end
        end
      end
    end
  end,
})

huaquan:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (data.extra_data or {}).huaquanUser == player and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huaquan.name)
  end,
})

return huaquan
