local osZhuidu = fk.CreateSkill {
  name = "os__zhuidu"
}

Fk:loadTranslationTable{
  ["os__zhuidu"] = "追妒",
  [":os__zhuidu"] = "出牌阶段限一次，你可选择一名受伤的其他角色并选择一项：1.你对其造成1点伤害；" ..
  "2.你弃置其装备区的一张牌。若其为女性角色，则你可背水：（在其执行完所有可执行的选项后）弃置一张牌。",

  ["#os__zhuidu"] = "选择一名受伤的其他角色，对其造成伤害或弃其装备",
  ["os__zhuidu_damage"] = "对其造成1点伤害",
  ["os__zhuidu_discard"] = "弃置其装备区的一张牌",
  ["beishui_os__zhuidu"] = "背水：你弃置一张牌",

  ["$os__zhuidu1"] = "到了阴司地府，你们也别想好过！",
  ["$os__zhuidu2"] = "髡头墨面，杀人诛心。",
}

osZhuidu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__zhuidu",
  can_use = function(self, player)
    return player:usedSkillTimes(osZhuidu.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isWounded()
  end,
  target_num = 1,
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets == 0 then return {} end
    local choices = { "os__zhuidu_damage" }
    local to = selected_targets[1]
    if #to:getCardIds("e") > 0 then
      table.insert(choices, "os__zhuidu_discard")
    end
    if to:isFemale() and not player:isNude() then
      table.insert(choices, "beishui_os__zhuidu")
    end
    return UI.OptionBox { options = choices , all_options = { "os__zhuidu_damage", "os__zhuidu_discard", "beishui_os__zhuidu" } }
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osZhuidu.name
    local player = effect.from
    local target = effect.tos[1]
    local choice = effect.interaction_data
    if choice ~= "os__zhuidu_discard" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
    if choice ~= "os__zhuidu_damage" and #target:getCardIds("e") > 0 then
      local card = room:askToChooseCard(
        player,
        {
          target = target,
          flag = "e",
          skill_name = skillName,
        }
      )
      room:throwCard(card, skillName, target, player)
    end
    if choice == "beishui_os__zhuidu" and player:isAlive() then
      room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false
        }
      )
    end
  end,
})

return osZhuidu
