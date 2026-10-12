local maozhu = fk.CreateSkill{
  name = "maozhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["maozhu"] = "茂著",
  [":maozhu"] = "锁定技，回合开始，或你绘制了一幅“地图”的所有城市，你将手牌中的花色补至4，并展开一幅“地图”。"..
  "回合结束时，你获得一个本回合已展开的“地图”技能，直到你下回合结束。",

  ["@[maozhu]"] = "茂著",
  ["@[:]maozhu_pool-turn"] = "茂著技能池",

  ["$maozhu1"] = "登东堂综文宣艺，忝作儒林之丈。",
  ["$maozhu2"] = "身负可育之材，当以栋梁处之。",
}

local M = require "packages.ol.pkg.ol_sp.peixiu_util"

maozhu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(maozhu.name)
  end,
  on_use = function(self, event, target, player, data)
    M.maozhuEffect(player)
  end,
})

maozhu:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(maozhu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[maozhu]", 0)

    local old_skill = player:getMark("maozhu_skill")
    if type(old_skill) == "string" then
      room:handleAddLoseSkills(player, "-" .. old_skill)
    end

    local pool = player:getTableMark("@[:]maozhu_pool-turn")
    if #pool == 0 then return end
    local skills = room:tableRandomPick(pool, 3)
    local choice = room:askToChoice(player, {
      skill_name = maozhu.name,
      choices = skills,
      detailed = true,
    })
    room:setPlayerMark(player, "maozhu_skill", choice)
    room:handleAddLoseSkills(player, choice)
  end,
})

Fk:addQmlMark({
  name = "maozhu",
  how_to_show = function(name, value, player)
    if type(value) ~= "table" then return " " end
    local ret = Fk:translate(value.name)
    local n = M.effectToBeDone(value.map)
    ret = ret .. " 剩" .. n
    return ret
  end,
  qml = {
    url = "packages/ol/qml/Maozhu.qml",
  }
})

return maozhu
