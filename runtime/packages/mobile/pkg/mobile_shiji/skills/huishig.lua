local huishi = fk.CreateSkill {
  name = "huishig",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["huishig"] = "辉逝",
  [":huishig"] = "限定技，出牌阶段，你可以选择一名角色，若其有未发动过的觉醒技且你的体力上限不小于存活角色数，你选择其中一项技能，"..
  "视为该角色满足其觉醒条件；否则其摸四张牌。最后你减2点体力上限。",

  ["#huishig"] = "辉逝：减2点体力上限，令一名角色的觉醒技视为满足条件（若其没有觉醒技则摸四张牌）",
  ["#huishig-choice"] = "辉逝：选择 %dest 一个觉醒技，视为满足觉醒条件",
  ["@huishig"] = "辉逝",

  ["$huishig1"] = "丧家之犬，主公实不足虑也。",
  ["$huishig2"] = "时事兼备，主公复有何忧？",
}

huishi:addEffect("active", {
  anim_type = "support",
  prompt = "#huishig",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(huishi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {}
    if #room.alive_players <= player.maxHp then
      choices = table.filter(target:getSkillNameList(), function(s)
        return Fk.skills[s]:hasTag(Skill.Wake) and target:usedSkillTimes(s, Player.HistoryGame) == 0
      end)
    end
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = huishi.name,
        prompt = "#huishig-choice::"..target.id,
      })
      room:addTableMarkIfNeed(target, "@huishig", choice)
      room:addTableMarkIfNeed(target, MarkEnum.StraightToWake, choice)
    else
      target:drawCards(4, huishi.name)
    end
    room:changeMaxHp(player, -2)
  end,
})

huishi:addEffect(fk.SkillEffect, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skill:hasTag(Skill.Wake) and
      table.contains(player:getTableMark("@huishig"), data.skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "@huishig", data.skill.name)
    room:removeTableMark(player, MarkEnum.StraightToWake, data.skill.name)
  end,
})

huishi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local ret, benefit = nil, 0
    for _, p in ipairs(ai:getEnabledTargets()) do
      local tmp = ai:getBenefitOfEvents(function(logic)
        if #ai.room.alive_players <= ai.player.maxHp and
          table.find(p:getSkillNameList(), function(s)
            return Fk.skills[s]:hasTag(Skill.Wake) and p:usedSkillTimes(s, Player.HistoryGame) == 0
          end) then
          logic.benefit = logic.benefit + 200
        else
          logic:drawCards(p, 4)
        end
      end)
      if tmp >= benefit then
        ret, benefit = p, tmp
      end
    end
    if ret then
      return { { }, { ret } }, benefit
    end
  end,
})

return huishi
