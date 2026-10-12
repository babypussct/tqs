local anxu = fk.CreateSkill {
  name = "m_ex__anxu",
}

Fk:loadTranslationTable{
  ["m_ex__anxu"] = "安恤",
  [":m_ex__anxu"] = "出牌阶段限一次，你可以令一名其他角色获得另一名其他角色的一张牌。若其获得的不是来自装备区里的牌，你摸一张牌。"..
    "当其以此法获得牌后，你可以令两者手牌较少的角色摸一张牌。",

  ["#m_ex__anxu-active"] = "安恤：选择两名其他角色，令先选择的角色获得后选择的角色的一张牌",
  ["#m_ex__anxu-draw"] = "安恤：是否令%dest摸一张牌",

  ["$m_ex__anxu1"] = "贤淑重礼，育人育己。",
  ["$m_ex__anxu2"] = "雨露均沾，后宫不乱。",
}

anxu:addEffect("active", {
  anim_type = "control",
  prompt = "#m_ex__anxu-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 1 and to_select:isNude() then return false end
    return #selected < 2 and to_select ~= player
  end,
  on_use = function(self, room, use)
    local player = use.from
    local target1 = use.tos[1]
    local target2 = use.tos[2]
    local card = room:askToChooseCard(target1, {
      target = target2,
      flag = "he",
      skill_name = anxu.name,
    })
    local can_draw = (room:getCardArea(card) ~= Card.PlayerEquip)
    room:obtainCard(target1, card, false, fk.ReasonPrey, target1, anxu.name)
    if can_draw and not player.dead then
      player:drawCards(1, anxu.name)
    end
    if not player.dead and not target1.dead and not target2.dead and target1:getHandcardNum() ~= target2:getHandcardNum() then
      if target1:getHandcardNum() > target2:getHandcardNum() then
        target1 = target2
      end
      if room:askToSkillInvoke(player, {
        skill_name = anxu.name,
        prompt = "#m_ex__anxu-draw::" .. target1.id,
      }) then
        target1:drawCards(1, anxu.name)
      end
    end
  end,
})

return anxu
