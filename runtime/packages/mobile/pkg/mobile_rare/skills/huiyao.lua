local huiyao = fk.CreateSkill {
  name = "huiyao",
}

Fk:loadTranslationTable{
  ["huiyao"] = "慧夭",
  [":huiyao"] = "出牌阶段限一次，你可以受到1点无来源伤害并选择一名其他角色，<font color='red'>视为</font>其对你选择的另一名角色造成1点伤害。",

  ["#huiyao"] = "慧夭：你可以受到1点无来源伤害，选择一名其他角色，令其<font color='red'>视为</font>造成伤害",
  ["#huiyao-choose"] = "慧夭：选择一名角色，视为 %dest 对其造成1点伤害",

  ["$huiyao1"] = "幸有仓舒为伴，吾不至居高寡寒。",
  ["$huiyao2"] = "通悟而无笃学之念，则必盈天下之叹也。",
}

huiyao:addEffect("active", {
  anim_type = "masochism",
  card_num = 0,
  target_num = 1,
  prompt = "#huiyao",
  can_use = function(self, player)
    return player:usedSkillTimes(huiyao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:damage{
      from = nil,
      to = player,
      damage = 1,
      skillName = huiyao.name,
    }
    if player.dead then return end
    local targets = room:getOtherPlayers(target, false)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = huiyao.name,
      prompt = "#huiyao-choose::"..target.id,
      cancelable = false,
    })
    room:damage{
      from = target,
      to = to[1],
      damage = 1,
      skillName = huiyao.name,
      isVirtualDMG = true,
    }
  end,
})

return huiyao
