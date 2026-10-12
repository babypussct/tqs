local osQirang = fk.CreateSkill {
  name = "os__qirang"
}

Fk:loadTranslationTable{
  ["os__qirang"] = "祈禳",
  [":os__qirang"] = "当装备牌移至你的装备区后，你可获得牌堆里的一张锦囊牌，然后你此阶段使用此牌无距离限制、不可被响应且可增加或减少一个目标。",

  ["@@os__qirang-phase-inhand"] = "祈禳",
  ["#os__qirang-target"] = "祈禳：你可为 %arg 增加或减少一个目标",

  ["$os__qirang1"] = "仙甲既来，岂无仙术乎。",
  ["$os__qirang2"] = "集母亲之智，效父亲之法，祈以七星。",
}

osQirang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osQirang.name) then
      return false
    end

    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Equip then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cids > 0 then
      local cid = cids[1]
      room:addTableMark(player, "_os__qirangTrick-phase", cid)
      room:obtainCard(player, cid, false, fk.ReasonPrey, player, osQirang.name, "@@os__qirang-phase-inhand")
    end
  end,
})

osQirang:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(player:getTableMark("_os__qirangTrick-phase"), card.id)
  end,
})

osQirang:addEffect(fk.AfterCardTargetDeclared, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card:isCommonTrick() and
      table.contains(player:getTableMark("_os__qirangTrick-phase"), data.card.id)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = data:getExtraTargets({ bypass_times = true })
    table.insertTableIfNeed(targets, data.tos)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__qirang-target:::" .. data.card:toLogString(),
        skill_name = osQirang.name,
        cancelable = true,
        no_indicate = false,
        target_tip_name = "addandcanceltarget_tip",
        extra_data = {
          targets = table.map(targets, Util.IdMapper),
          extra_data = table.map(data.tos, Util.IdMapper),
        }
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__qirang", "special")
    player:broadcastSkillInvoke("os__qirang")
    local to = event:getCostData(self).tos[1]
    if table.contains(data.tos, to) then
      data:removeTarget(to)
    else
      data:addTarget(to)
    end
  end,
})

osQirang:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.card.type == Card.TypeTrick and
      table.contains(player:getTableMark("_os__qirangTrick-phase"), data.card.id)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.players) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

return osQirang
