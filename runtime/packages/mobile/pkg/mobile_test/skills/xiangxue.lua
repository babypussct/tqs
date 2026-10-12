
local xiangxue = fk.CreateSkill {
  name = "xiangxue",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:getMark("@xiangxue") >= 9 then
      return "xiangxue_update2"
    elseif player:getMark("@xiangxue") >= 6 then
      return "xiangxue_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["xiangxue"] = "想学",
  [":xiangxue"] = "锁定技，你每使用2张未使用过的牌名的牌，获得等量个“惘”标记并摸1张牌，然后若“惘”数为：<br>"..
  "6，交换上文中的两个数字；<br>9，删除上文中的“未”；<br>12，失去此技能。",

  [":xiangxue_update"] = "锁定技，你每使用1张未使用过的牌名的牌，获得等量个“惘”标记并摸2张牌，然后若“惘”数为：<br>"..
  "9，删除上文中的“未”；<br>12，失去此技能。",
  [":xiangxue_update2"] = "锁定技，你每使用1张使用过的牌名的牌，获得等量个“惘”标记并摸2张牌，然后若“惘”数为12，失去此技能。",

  ["@xiangxue"] = "惘",
  ["@$xiangxue"] = "想学已学",

  ["$xiangxue1"] = "学而思之，则朕必不罔矣。",
  ["$xiangxue2"] = "朕早有言在先，此生必能学会！",
  ["$xiangxue3"] = "此前所学之事，再思当可行之。",
  ["$xiangxue4"] = "愈思则愈清，愈学则愈明。",
  ["$xiangxue5"] = "五年罔殆，三年思学，朕当为好学之人！",
}

xiangxue:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangxue.name) and
      (data.extra_data or {}).xiangxue
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@xiangxue") >= 6 then
      room:addPlayerMark(player, "@xiangxue", 1)
      player:drawCards(2, xiangxue.name)
      if player:getMark("@xiangxue") >= 12 then
        room:handleAddLoseSkills(player, "-xiangxue")
      end
    else
      room:addPlayerMark(player, "@xiangxue", 2)
      player:drawCards(1, xiangxue.name)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangxue.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@xiangxue") >= 9 then
      if room:addTableMarkIfNeed(player, "xiangxue_new", data.card.trueName) then
        room:setPlayerMark(player, "@$xiangxue", player:getMark("xiangxue_new"))
      else -- 9~12用过了发动
        data.extra_data = data.extra_data or {}
        data.extra_data.xiangxue = true
      end
    elseif room:addTableMarkIfNeed(player, "xiangxue_new", data.card.trueName) then -- 小于9没用过发动
      room:setPlayerMark(player, "@$xiangxue", player:getMark("xiangxue_new")) -- 宝宝标记
      if player:getMark("@xiangxue") >= 6 or #player:getMark("xiangxue_new") % 2 == 0 then -- 6~9或2的倍数
        data.extra_data = data.extra_data or {}
          data.extra_data.xiangxue = true
      end
    end
  end,
})

xiangxue:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@xiangxue", 0)
  room:setPlayerMark(player, "@$xiangxue", 0)
  room:setPlayerMark(player, "xiangxue_new", 0)
end)

return xiangxue
