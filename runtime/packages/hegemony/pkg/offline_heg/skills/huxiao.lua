local huxiao = fk.CreateSkill{
  name = "ofl_heg__huxiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__huxiao"] = "虎啸",
  [":ofl_heg__huxiao"] = "锁定技，当你造成火焰伤害后，受伤角色摸一张牌，本回合你对其使用的下三张牌不计入次数。",

  ["@@ofl_heg__huxiao-turn"] = "虎啸",

  ["$ofl_heg__huxiao1"] = "大仇未报，还不能放弃！",
  ["$ofl_heg__huxiao2"] = "虎父无犬女！",
}

huxiao:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huxiao.name) and
      data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.to:drawCards(1, huxiao.name)
    if data.to.dead or player.dead then return end
    room:addPlayerMark(data.to, "@@ofl_heg__huxiao-turn", 1)
    room:setPlayerMark(player, "ofl_heg__huxiao_"..data.to.id.."-turn", 3)
  end,
})

huxiao:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      table.find(data.tos, function (p)
        return player:getMark("ofl_heg__huxiao_"..p.id.."-turn") > 0
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    data.extraUse = true
    for _, p in ipairs(data.tos) do
      local mark = "ofl_heg__huxiao_"..p.id.."-turn"
      if player:getMark(mark) > 0 then
        room:removePlayerMark(player, mark, 1)
        if player:getMark(mark) == 0 then
          room:removePlayerMark(p, "@@ofl_heg__huxiao-turn", 1)
        end
      end
    end
  end,
})

huxiao:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and player:getMark("ofl_heg__huxiao_"..to.id.."-turn") > 0
  end,
})

return huxiao
