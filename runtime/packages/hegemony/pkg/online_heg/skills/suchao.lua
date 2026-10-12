
local suchao = fk.CreateSkill{
  name = "ol_heg__suchao",
}

Fk:loadTranslationTable{
  ["ol_heg__suchao"] = "肃朝",
  [":ol_heg__suchao"] = "出牌阶段限一次，你可以对至多三名手牌数大于你的角色各造成1点伤害。"..
  "若如此做，此阶段结束时，这些角色各回复1点体力且可以对你使用一张【杀】。",

  ["#ol_heg__suchao"] = "肃朝：对至多三名角色各造成1点伤害，此阶段结束时这些角色各回复1点体力且可以对你使用【杀】",
  ["#ol_heg__suchao-slash"] = "肃朝：你可以对 %src 使用一张【杀】",

  ["$ol_heg__suchao1"] = "你们是要谋反吗？",
  ["$ol_heg__suchao2"] = "想杀我，你们就这点能耐？",
}

suchao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol_heg__suchao",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return player:usedSkillTimes(suchao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select:getHandcardNum() > player:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local mark = player:getTableMark("ol_heg__suchao-phase")
    table.insertTable(mark, effect.tos)
    room:setPlayerMark(player, "ol_heg__suchao-phase", mark)
    room:sortByAction(effect.tos)
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = suchao.name,
        }
      end
    end
  end,
})

suchao:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("ol_heg__suchao-phase") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = player:getTableMark("ol_heg__suchao-phase")
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:recover{
          who = p,
          num = 1,
          recoverBy = p,
          skillName = suchao.name,
        }
      end
    end
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead then
          local use = room:askToUseCard(p, {
            skill_name = suchao.name,
            pattern = "slash",
            prompt = "#ol_heg__suchao-slash:"..player.id,
            extra_data = {
              bypass_distances = true,
              bypass_times = true,
              exclusive_targets = { player.id },
            }
          })
          if use then
            use.extraUse = true
            room:useCard(use)
          end
      end
    end
  end,
})

return suchao
