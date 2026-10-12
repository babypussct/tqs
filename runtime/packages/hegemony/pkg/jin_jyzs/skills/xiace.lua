local xiace = fk.CreateSkill{
  name = "heg__xiace",
}

Fk:loadTranslationTable{
  ["heg__xiace"] = "黠策",
  [":heg__xiace"] = "若当前回合角色有【杀】的剩余使用次数，你可以将一张牌当【无懈可击】使用，" ..
    "并令当前回合角色【杀】的剩余使用次数-1，然后你可以变更副将。",

  ["@heg__xiace_slash-phase"] = "黠策",

  ["$heg__xiace1"] = "风之积非厚，其负大翼也无力。",
  ["$heg__xiace2"] = "人情同于抔土，岂穷达而异心。",
}

local H = require "packages.hegemony.util"

xiace:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  card_num = 1,
  handly_pile = true,
  enabled_at_nullification = function (self, player, response)
    if player:isNude() then return false end
    local curPlayer = Fk:currentRoom():getCurrent()
    if curPlayer then
      local card = Fk:cloneCard("slash")
      local card_skill = card.skill
      local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
      for _, skill in ipairs(status_skills) do
        if skill:bypassTimesCheck(curPlayer, card_skill, Player.HistoryPhase, card, nil) then return true end
      end
      local limit = card_skill:getMaxUseTime(curPlayer, Player.HistoryPhase, card, nil)
      if not limit or curPlayer:usedCardTimes("slash", Player.HistoryPhase) < limit then
        return true
      end
    end
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("nullification")
    c.skillName = xiace.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function (self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.heg__xiaceUser = player.id
    local room = player.room
    local curPlayer = room:getCurrent() --[[@as ServerPlayer]]
    if curPlayer and curPlayer:isAlive() then
      room:addPlayerMark(curPlayer, "@heg__xiace_slash-phase")
    end
  end,
})
xiace:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and (data.extra_data or {}).heg__xiaceUser == player.id
      and player:isAlive()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if room:askToChoice(player, {
      choices = { "transformDeputy", "Cancel" },
      skill_name = xiace.name,
    }) ~= "Cancel" then
      H.transformGeneral(room, player)
    end
  end
})
xiace:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:getMark("@heg__xiace_slash-phase") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return -player:getMark("@heg__xiace_slash-phase")
    end
  end
})

return xiace
