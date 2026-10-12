local qiangang = fk.CreateSkill {
  name = "qiangang",
}

Fk:loadTranslationTable{
  ["qiangang"] = "乾纲",
  [":qiangang"] = "出牌阶段，你可以<a href='#RuMoDesc'><font color='red'>入魔</font></a>，失去〖天恩〗，" ..
  "然后本局游戏当你使用【杀】指定唯一目标时，额外执行目标所选择过的所有“权御”效果。",

  ["#qiangang-active"] = "乾纲：你可以入魔，失去“天恩”，本局使用【杀】指定唯一目标时执行其选过的“权御”效果",
  ["#qiangang-choice"] = "乾纲：请为%arg选择任意项“权御”效果",

  ["$qiangang1"] = "清浊之分，朕说无用便是无用。",
  ["$qiangang2"] = "这天下欠朕的，该还了。",
  ["$qiangang3"] = "朕心即天意，卿当跪听天怒！",
}

qiangang:addEffect("active", {
  prompt = "#qiangang-active",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return not player:hasSkill("#rumo", true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:handleAddLoseSkills(player, "#rumo", nil, false)
    room:handleAddLoseSkills(player, "-tianen")
    room:setPlayerMark(player, "qiangang_buff-noclear", 1)
  end,
})

local doQuanyuEffect = function(player, effect, data)
  local room = player.room
  if effect == "quanyu_baihong_name" then
    data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
  elseif effect == "quanyu_qingming_name" then
    if not player:isAlive() then
      return
    end

    local targets = data:getExtraTargets({ bypass_times = true, bypass_distances = true })
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = qiangang.name,
          prompt = "#quanyu-choose:::" .. data.card:toLogString(),
          cancelable = false,
        }
      )

      data:addTarget(tos[1])
    end
  elseif effect == "quanyu_zidian_name" then
    data.use.disresponsiveList = room:getAllPlayers(false)
  elseif effect == "quanyu_baili_name" then
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
  elseif effect == "quanyu_liuxing_name" and not data.use.extraUse then
    data.use.extraUse = true
    player:addCardUseHistory("slash", -1)
  end

  data.extra_data = data.extra_data or {}
  data.extra_data.quanyuEffect = data.extra_data.quanyuEffect or {}
  table.insertIfNeed(data.extra_data.quanyuEffect, effect)
end

qiangang:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      data:isOnlyTarget(data.to) and
      player:hasSkill(qiangang.name) and
      player:getMark("qiangang_buff-noclear") > 0 and
      table.find(data.to:getTableMark("quanyu_chosen-noclear"), function(name)
        return
          not table.contains((data.extra_data or {}).quanyuEffect or {}, name) and
          not (
            name == "quanyu_qingming_name" and
            #data:getExtraTargets({ bypass_times = true, bypass_distances = true }) == 0
          )
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    for _, name in ipairs(data.to:getTableMark("quanyu_chosen-noclear")) do
      if not table.contains((data.extra_data or {}).quanyuEffect or {}, name) then
        doQuanyuEffect(player, name, data)
      end
    end
  end,
})

qiangang:addEffect("targetmod", {
  target_tip_func = function(self, player, to_select, selected, selected_cards, card, selectable)
    if
      card.trueName == "slash" and
      selectable and player:getMark("qiangang_buff-noclear") > 0 and
      #to_select:getTableMark("quanyu_chosen-noclear") > 0
    then
      return table.concat(
        table.map(to_select:getTableMark("quanyu_chosen-noclear"), function(effect)
          return Fk:translate(effect)[1]
        end),
        ""
      )
    end
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and
      player:hasSkill(qiangang.name) and player:getMark("qiangang_buff-noclear") > 0 and
      to and table.contains(to:getTableMark("quanyu_chosen-noclear"), "quanyu_liuxing_name")
  end,
})

qiangang:addAcquireEffect(function(self, player)
  local room = player.room
  if not room:hasSkill("#quanyu_bixie") then
    room:addSkill("#quanyu_bixie")
  end
end)

return qiangang
