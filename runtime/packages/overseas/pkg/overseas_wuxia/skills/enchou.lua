local osEnchou = fk.CreateSkill {
  name = "os__enchou"
}

Fk:loadTranslationTable{
  ["os__enchou"] = "恩仇",
  [":os__enchou"] = "出牌阶段限一次，你可观看一名有装备栏被废除的其他角色的手牌并获得其中一张牌，然后你恢复其一个装备栏。",

  ["os__enchou_get"] = "获得",
  ["#os__enchou-ask"] = "恩仇：获得 %dest 一张手牌，然后恢复其一个装备栏",
  ["#os__enchou-choice"] = "恩仇：恢复 %dest 一个装备栏",
  ["#os__enchou"] = "你可观看一名有装备栏被废除的其他角色的手牌并获得其中一张，恢复其一个装备栏。",

  ["$os__enchou1"] = "江湖快意，恩仇必报！",
  ["$os__enchou2"] = "今日之因，明日之果！"
}

--- 获取被废除的装备栏
---@param player Player
local function getSealedEquipSlot(player)
  local all_slots = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
  return table.filter(all_slots, function(slot) return table.contains(player.sealedSlots, slot) end)
end

osEnchou:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#os__enchou",
  times = function (self, player)
    return 1 - player:usedSkillTimes(osEnchou.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(osEnchou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(to_select) > 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osEnchou.name
    local player = effect.from
    local target = effect.tos[1]
    local cids = target:getCardIds("h")
    local cards, _ = room:askToChooseCardsAndChoice(player, {
      cards = cids,
      choices = {"os__enchou_get"},
      skill_name = skillName,
      prompt = "#os__enchou-ask::" .. target.id
    })
    room:obtainCard(player, cards[1], false, fk.ReasonPrey, player, skillName)
    if target:isAlive() and player:isAlive() then
      local choices = getSealedEquipSlot(target)
      if #choices > 0 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = skillName,
          prompt = "#os__enchou-choice::" .. target.id,
        })
        room:resumePlayerArea(target, {choice})
      end
    end
  end,
})

return osEnchou
