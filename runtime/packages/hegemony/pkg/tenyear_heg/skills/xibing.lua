local xibing = fk.CreateSkill{
  name = "ty_heg__xibing",
}
local H = require "packages.hegemony.util"
xibing:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(xibing.name) and target ~= player and target.phase == Player.Play and
      data.card.color == Card.Black and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #data:getAllTargets() == 1) then return false end
    local events = target.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      return use.from == target and use.card.color == Card.Black and (use.card.trueName == "slash" or use.card:isCommonTrick())
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == target.room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = xibing.name,
      prompt = "#ty_heg__xibing-invoke::"..target.id
    }) then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = math.min(target.hp, 5) - target:getHandcardNum()
    local cards
    if num > 0 then
      cards = target:drawCards(num, xibing.name)
    end
    if H.allGeneralsRevealed(player) and H.allGeneralsRevealed(target)
      and room:askToChoice(player, {
        choices = {"ty_heg__xibing_hide::" .. target.id,
        skill_name = "Cancel"},
        prompt = xibing.name,
      }) ~= "Cancel" then
      for _, p in ipairs({player, target}) do
        local isDeputy = H.doHideGeneral(room, player, p, xibing.name)
        room:setPlayerMark(p, "@ty_heg__xibing_reveal-turn", H.getActualGeneral(p, isDeputy))
        local record = type(p:getMark(MarkEnum.RevealProhibited .. "-turn")) == "table" and p:getMark(MarkEnum.RevealProhibited .. "-turn") or {}
        table.insert(record, isDeputy and "d" or "m")
        room:setPlayerMark(p, MarkEnum.RevealProhibited .. "-turn", record)
      end
    end
    if cards and not target.dead then
      room:setPlayerMark(target, "@@ty_heg__xibing-turn", 1)
    end
  end,
})
xibing:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@ty_heg__xibing-turn") == 0 then return false end 
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__xibing"] = "息兵",
  [":ty_heg__xibing"] = "当其他角色于其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一目标后，若其于此回合内未使用过黑色【杀】或黑色普通锦囊牌，你可令其将手牌摸至体力值"..
  "（至多摸至五张），然后若你与其均明置了所有武将牌，则你可暗置你与其各一张武将牌且本回合不能明置以此法暗置的武将牌。若其因此摸牌，其本回合不能使用手牌。",

  ["#ty_heg__xibing-invoke"] = "你想对 %dest 发动 “息兵” 吗？",
  ["ty_heg__xibing_hide"] = "暗置你与%dest各一张武将牌且本回合不能明置",
  ["@ty_heg__xibing_reveal-turn"] = "息兵禁亮",
  ["@@ty_heg__xibing-turn"] = "息兵 禁用手牌",

  ["$ty_heg__xibing1"] = "千里运粮，非用兵之利。",
  ["$ty_heg__xibing2"] = "宜弘一代之治，绍三王之迹。",
}

return xibing
