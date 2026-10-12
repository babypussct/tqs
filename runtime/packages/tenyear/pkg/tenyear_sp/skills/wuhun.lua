local wuhun = fk.CreateSkill {
  name = "ty__wuhun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ty__wuhun"] = "武魂",
  [":ty__wuhun"] = "锁定技，当你造成/受到1点伤害后，你令受伤角色/伤害来源获得1枚“梦魇”；"..
  "当你死亡时，你令拥有“梦魇”标记最多的一名其他角色进行判定，若结果不为【桃】或【桃园结义】，其死亡。",

  ["@nightmare"] = "梦魇",
  ["#ty__wuhun-choose"] = "武魂：选择一名“梦魇”最多的其他角色",

  ["$ty__wuhun1"] = "",
  ["$ty__wuhun2"] = "",
}

wuhun:addLoseEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@nightmare", 0)
  end
end)

wuhun:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuhun.name) and
      not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(data.to, "@nightmare", data.damage)
  end,
})

wuhun:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuhun.name) and
      data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(data.from, "@nightmare", data.damage)
  end,
})

wuhun:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuhun.name, false, true) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@nightmare") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return table.every(room:getOtherPlayers(player, false), function(p2)
        return p:getMark("@nightmare") >= p2:getMark("@nightmare")
      end)
    end)
    if #targets > 1 then
      targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = wuhun.name,
        prompt = "#wuhun-choose",
        cancelable = false,
      })
    end
    local to = targets[1]
    local judge = {
      who = to,
      reason = wuhun.name,
      pattern = "^(peach,god_salvation)",
    }
    room:judge(judge)
    if not judge:matchPattern() or to.dead then return end
    room:killPlayer{
      who = to,
      killer = player,
    }
  end,
})
--[[
wuhun:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = wuhun.name,
      benefit_func = function (logic, p)
        logic:killPlayer()
      end,
    })
  end,
})]]

return wuhun
