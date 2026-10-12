local jilun = fk.CreateSkill {
  name = "jilun"
}

Fk:loadTranslationTable{
  ["jilun"] = "机论",
  [":jilun"] = "当你受到伤害后，若你拥有技能“急筹”，你可以选择一项：1.摸X张牌（X为“急筹”已记录过的牌名数，至少为1且至多为3）；"..
  "2.视为使用一张基本牌或目标数不大于X且“急筹”记录过的普通锦囊牌（每种牌名限一次）。",

  ["jilun_draw"] = "摸%arg张牌",
  ["jilun_use"] = "视为使用一张基本牌或目标数不大于%arg且“急筹”记录过的普通锦囊牌",
  ["#jilun-ask"] = "机论：请选择一项",

  ["$jilun1"] = "树化建业，慎在民时。",
  ["$jilun2"] = "推极利弊，当禁文巧之词。",
}

jilun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilun.name) and player:hasSkill("jichou", true)
  end,
  on_cost = function(self, event, target, player)
    local num = math.min(math.max(#player:getTableMark("@$jichou"), 1), 3)
    local choices = { "jilun_draw:::" .. num, "Cancel" }

    local canUseNames = player:getViewAsCardNames(
      jilun.name,
      Fk:getAllCardNames("b"),
      nil,
      player:getTableMark("jilun_used_basic")
    )
    table.insertTable(
      canUseNames,
      table.filter(
        player:getViewAsCardNames(jilun.name, player:getTableMark("jilun_record")),
        function(name)
          if name == "collateral" then -- 临时处理借刀
            return true
          end
          return #Fk:cloneCard(name):getDefaultTarget(player) <= num
        end
      )
    )
    if #canUseNames > 0 then
      table.insert(choices, 2, "jilun_use:::" .. num)
    end
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = jilun.name,
        prompt = "#jilun-ask",
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice, canUseNames = canUseNames })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = jilun.name
    local room = player.room
    local choice = event:getCostData(self).choice
    local canUseNames = event:getCostData(self).canUseNames

    local num = math.min(math.max(#player:getTableMark("@$jichou"), 1), 3)
    if choice:startsWith("jilun_use") then
      local use = room:askToUseVirtualCard(
        player,
        {
          name = canUseNames,
          skill_name = skillName,
          prompt = "jilun_use:::" .. num,
          extra_data = {
            bypass_times = false,
            extraUse = false,
          },
          cancelable = false,
          skip = true,
        }
      )
      if use then
        if use.card.type == Card.TypeBasic then
          room:addTableMarkIfNeed(player, "jilun_used_basic", use.card.trueName)
        else
          room:removeTableMark(player, "jilun_record", use.card.name)
        end
        room:useCard(use)
      end
    else
      player:drawCards(num, skillName)
    end
  end,
})

return jilun
