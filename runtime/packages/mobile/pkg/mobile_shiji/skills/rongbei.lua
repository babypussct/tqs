local rongbei = fk.CreateSkill {
  name = "rongbei",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["rongbei"] = "戎备",
  [":rongbei"] = "限定技，出牌阶段，你可以选择一名装备区有空置装备栏的角色，其为每个空置的装备栏从牌堆或弃牌堆随机使用一张对应类别的装备。",

  ["#rongbei"] = "戎备：令一名角色每个空置的装备栏随机使用一张装备",

  ["$rongbei1"] = "我军虽以德感民，亦不可废弛武备。",
  ["$rongbei2"] = "缮甲训卒，广为戎备，不失伐吴之机。",
}

rongbei:addEffect("active", {
  anim_type = "support",
  prompt = "#rongbei",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(rongbei.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("e") < #to_select:getAvailableEquipSlots()
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    for _, slot in ipairs(target:getAvailableEquipSlots()) do
      if target.dead then return end
      local type = Util.convertSubtypeAndEquipSlot(slot)
      if #target:getEquipments(type) < #target:getAvailableEquipSlots(type) then
        local ids = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
          return Fk:getCardById(id).sub_type == type and target:canUseTo(Fk:getCardById(id), target)
        end)
        if #ids > 0 then
          room:useCard{
            from = target,
            tos = { target },
            card = Fk:getCardById(room:tableRandomPick(ids)),
          }
        end
      end
    end
  end,
})

return rongbei
