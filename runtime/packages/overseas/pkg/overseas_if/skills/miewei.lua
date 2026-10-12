local miewei = fk.CreateSkill{
  name = "os__miewei",
}

Fk:loadTranslationTable{
  ["os__miewei"] = "灭围",
  [":os__miewei"] = "①出牌阶段开始时，你可以令此阶段使用【杀】次数上限改为你攻击范围内的角色数。"..
    "②当你使用【杀】对目标角色造成伤害时，此伤害+X（X为本回合成为过【杀】目标的角色数，至多为5）。",

  ["#os__miewei-invoke"] = "你可发动 灭围，令此阶段使用【杀】次数上限改为你攻击范围内的角色数",
  ["@@os__miewei_atkrange-phase"] = "灭围 已发动",

  ["$os__miewei1"] = "龙骧、陷阵，焉挡我虎贲之师！",
  ["$os__miewei2"] = "汝等千军，今亦为吾一人所围！",
}

miewei:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = self.name, prompt = "#os__miewei-invoke"})
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__miewei_atkrange-phase", 1)
  end
})
miewei:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    return card and player:getMark("@@os__miewei_atkrange-phase") > 0 and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase and #table.filter(Fk:currentRoom().alive_players, function(p)
      return player:inMyAttackRange(p) end) - 1 or nil
  end
})

miewei:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and
      data.card.trueName == "slash" and data.by_user
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local tars = {}
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.card.trueName == "slash" then
        table.insertTableIfNeed(tars, use.tos)
        if #tars >= 5 then return true end
      end
    end, Player.HistoryTurn)
    data:changeDamage(#tars)
  end
})

return miewei
