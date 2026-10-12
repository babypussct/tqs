local feifu = fk.CreateSkill {
  name = "os__feifu",
  tags = { Skill.Compulsory, Skill.Switch },
}

Fk:loadTranslationTable{
  ["os__feifu"] = "非服",
  [":os__feifu"] = "锁定技，转换技，阳：当你使用【杀】指定唯一目标后；阴：当你成为【杀】的唯一目标后；" ..
  "目标角色须交给此【杀】的使用者一张牌，若此牌为装备牌，获得牌的角色可以使用此牌。",

  ["#os__feifu-give"] = "非服：请交给 %src 一张牌",
  ["#os__feifu-use"] = "非服：你可以使用%arg",

  ["$os__feifu1"] = "此亦久矣，其能复几！",
  ["$os__feifu2"] = "君既赌输，理当再脱一件。",
  ["$os__feifu3"] = "以侯归第？终败于其！",
  ["$os__feifu4"] = "君若如此，让我如何见人？"
}
local spec = {
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = feifu.name
    local room = player.room

    local user = data.from
    local to = data.to
    if not (user:isAlive() and to:isAlive()) then
      return false
    end

    room:doIndicate(player, { player == user and data.to or data.from })
    local cids = room:askToCards(
      to,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
        prompt = "#os__feifu-give:" .. data.from.id,
      }
    )
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, user, fk.ReasonGive, skillName, nil, false, to)
      if not user:isAlive() then
        return false
      end

      local card = Fk:getCardById(cids[1])
      if card.type == Card.TypeEquip and room:getCardOwner(card) == user and room:getCardArea(card) == Card.PlayerHand then
        local cardName = card.name
        room:askToUseRealCard(
          user,
          {
            pattern = cardName .. "|.|.|.|.|." .. cids[1],
            skill_name = skillName,
            prompt = "#os__feifu-use:::" .. card:toLogString(),
          }
        )
      end
    end
  end,
}

feifu:addEffect(fk.TargetSpecified, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(feifu.name) and
      data.card.trueName == "slash" and
      data:isOnlyTarget(data.to) and
      player:getSwitchSkillState(feifu.name) == fk.SwitchYang and
      not data.to:isNude()
  end,
  on_use = spec.on_use,
})

feifu:addEffect(fk.TargetConfirmed, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(feifu.name) and
      data.card.trueName == "slash" and
      data:isOnlyTarget(data.to) and
      player:getSwitchSkillState(feifu.name) == fk.SwitchYin and
      not data.to:isNude()
  end,
  on_use = spec.on_use,
})

return feifu
