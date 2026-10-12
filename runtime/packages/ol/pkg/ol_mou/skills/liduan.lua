local liduan = fk.CreateSkill {
  name = "liduan",
}

Fk:loadTranslationTable{
  ["liduan"] = "戾断",
  [":liduan"] = "你使用【杀】后，令你使用的下一张锦囊牌可以多指定一个目标，你使用锦囊牌后，令你使用的下一张【杀】可以多指定一个目标。",

  ["@liduan"] = "戾断",
  ["#liduan-choose"] = "戾断：你可以为%arg额外指定至多%arg2个目标",

  ["$liduan1"] = "持专断之勇，兼详择之智！",
  ["$liduan2"] = "呼吸之间，即息天下之乱。",
}

liduan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liduan.name) and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@liduan")
    local str = data.card.trueName == "slash" and "trick_char" or "slash"
    if mark[1] == str then
      mark[2] = (mark[2] or 0) + 1
    else
      mark = { str, 1 }
    end
    room:setPlayerMark(player, "@liduan", mark)
  end,
})

liduan:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(liduan.name) then
      local str
      if data.card.trueName == "slash" then
        str = "slash"
      elseif data.card.type == Card.TypeTrick then
        str = "trick_char"
      else
        return
      end
      local mark = player:getTableMark("@liduan")
      return #mark == 2 and mark[1] == str
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@liduan")
    local n = mark[2] or 0
    if n < 1 then return end
    local tos = data:getExtraTargets({ bypass_distances = false })
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = n,
        targets = tos,
        skill_name = liduan.name,
        prompt = "#liduan-choose:::"..data.card:toLogString()..":"..n,
        cancelable = true,
      })
      if #tos > 0 then
        data:addTarget(tos)
      end
    end
  end,
})

return liduan
