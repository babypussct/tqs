local duanxie = fk.CreateSkill{
  name = "duanxie",
}

Fk:loadTranslationTable{
  ["duanxie"] = "断绁",
  [":duanxie"] = "出牌阶段限一次，你可以令至多四名其他角色横置，然后你横置，若你因此横置的其他角色数大于X，你受到1点无来源伤害（X为你已损失的体力值）。",

  ["$duanxie1"] = "区区绳索就想挡住吾等去路？！",
  ["$duanxie2"] = "以身索敌，何惧同伤！",
}

duanxie:addEffect("active", {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(duanxie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player and not to_select.chained
  end,
  min_target_num = 1,
  max_target_num = function(self, player)
    return 4
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    for _, target in ipairs(effect.tos) do
      if not target.chained then
        target:setChainState(true)
      end
    end
    if not player.chained then
      player:setChainState(true)
    end
    if #effect.tos > player:getLostHp() and not player.dead then
      room:damage({
        to = player,
        damage = 1,
        skillName = duanxie.name,
      })
    end
  end,
})

return duanxie
