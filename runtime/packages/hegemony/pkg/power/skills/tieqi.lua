local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

local tieqi = fk.CreateSkill {
  name = "xuanhuo__hs__tieqi",
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__tieqi_shouyue"
    else
      return "xuanhuo__hs__tieqi"
    end
  end,
}

tieqi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tieqi.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    local judge = {
      who = player,
      reason = tieqi.name,
      pattern = ".|.|spade,club,heart,diamond",
    }
    if player.dead then return end
    local choices = {}
    if to.general ~= "anjiang" then
      table.insert(choices, to.general)
    end
    if to.deputyGeneral ~= "anjiang" then
      table.insert(choices, to.deputyGeneral)
    end
    local all_choices = { to.general, to.deputyGeneral }
    local disable_choices = table.filter(all_choices, function(g) return not table.contains(choices, g) end)
    if #choices > 0 then
      local choice
      if H.hasHegLordSkill(room, player, "shouyue") and #choices > 1 then
        choice = choices
      else
        choice = U.askToChooseGeneralsAndChoice(player, {
          skill_name = tieqi.name,
          generals = all_choices,
          prompt = "#hs__tieqi-ask::" .. to.id,
          max_num = 1,
          disable_choices = disable_choices
        })
      end
      local generals = to:getTableMark("@hs__tieqi-turn")
      local skills = to:getTableMark("_hs__tieqi-turn")
      for _, c in ipairs(choice) do
        table.insertIfNeed(generals, c)
        for _, skill_name in ipairs(Fk.generals[c]:getSkillNameList()) do
          local skill = Fk.skills[skill_name]
          if not skill:hasTag(Skill.Compulsory) and skill:isPlayerSkill(to) then
            table.insertIfNeed(skills, skill_name)
          end
        end
        room:sendLog {
          type = "#HsTieqiTo",
          from = player.id,
          to = { to.id },
          arg = c,
        }
      end
      room:setPlayerMark(to, "@hs__tieqi-turn", generals)
      room:setPlayerMark(to, "_hs__tieqi-turn", skills)
    end
    room:judge(judge)
    if judge.card.suit ~= Card.NoSuit then
      if #room:askToDiscard(to, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = tieqi.name,
            cancelable = true,
            pattern = ".|.|" .. judge.card:getSuitString(),
            prompt = "#hs__tieqi-discard:::" .. judge.card:getSuitString(),
          }) == 0 then
        data.disresponsive = true
      end
    end
  end,
})

tieqi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if from:getMark("_hs__tieqi-turn") ~= 0 then
      return table.contains(from:getMark("_hs__tieqi-turn"), skill.name) and
          not skill:hasTag(Skill.Compulsory) and skill:isPlayerSkill(from)
    end
  end
})

tieqi:addTest(function(room, me)
  local comp2 = room.players[2]
  FkTest.setNextReplies(me, { "1", json.encode { cards = { "guojia" }, chioce = "OK" }, "1" })
  FkTest.setNextReplies(comp2, { "__cancel", "1" })
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, tieqi.name)
    room:changeHero(comp2, "guojia", true, false, true, false, true)
    room:useVirtualCard("slash", nil, me, { comp2 })
  end)
  lu.assertEquals(comp2.hp, 3)
  lu.assertIsTrue(comp2:isKongcheng())
  lu.assertIsFalse(comp2:hasSkill("yiji"))
end)

Fk:loadTranslationTable {
  ["xuanhuo__hs__tieqi"] = "铁骑",
  [":xuanhuo__hs__tieqi"] = "当你使用【杀】指定目标后，你可判定，令其本回合一张明置的武将牌非锁定技失效，其需弃置一张与判定结果花色相同的牌，否则其不能使用【闪】抵消此【杀】。",
}

return tieqi
