local qiangyi = fk.CreateSkill {
  name = "m_qiangyi",
  mode_skill = true,
}

Fk:loadTranslationTable{
  ["m_qiangyi"] = "强易",
  [":m_qiangyi"] = "每名角色限一次，你可以获得一名其他角色的一张手牌并交给其一张手牌。",

  ["#m_qiangyi"] = "强易：你可以拿别人一张手牌并还给他一张",
  ["#m_qiangyi-give"] = "强易：请交给 %dest 一张手牌",
}

qiangyi:addEffect("active", {
  target_num = 1,
  card_num = 0,
  prompt = "#m_qiangyi",
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:hasMark(qiangyi.name)
      and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    if to:isKongcheng() then return end

    room:addPlayerMark(to, qiangyi.name)

    local id = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = qiangyi.name
    })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, qiangyi.name)

    if not player:isKongcheng() and not to.dead and not player.dead then
      local c = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = qiangyi.name,
        prompt = "#m_qiangyi-give::" .. to.id,
        cancelable = false,
      })[1]
      room:moveCardTo(c, Player.Hand, to, fk.ReasonGive, qiangyi.name, nil, false, player)
    end
  end,
})

return qiangyi
