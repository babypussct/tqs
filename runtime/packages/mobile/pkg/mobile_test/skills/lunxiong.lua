local lunxiong = fk.CreateSkill {
  name = "lunxiong",
}

Fk:loadTranslationTable{
  ["lunxiong"] = "论雄",
  [":lunxiong"] = "当你造成或受到伤害后，你可以弃置点数唯一最大的手牌，然后摸三张牌，你本局游戏以此法弃置牌的点数须大于此牌。",

  ["#lunxiong-invoke"] = "论雄：你可以弃置点数唯一最大的手牌（至少为%arg点），摸三张牌",

  ["$lunxiong1"] = "英以其聪谋始，以其明见机，待雄之胆行之。",
  ["$lunxiong2"] = "雄以其力服众，以其勇排难，待英之智成之。",
}

local lunxiong_spec = {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lunxiong.name) and not player:isKongcheng() and
      player:getMark(lunxiong.name) < 13
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id)
      local num = Fk:getCardById(id).number
      return num > player:getMark(lunxiong.name) and
        table.every(player:getCardIds("h"), function(id2)
          return num >= Fk:getCardById(id2).number
        end) and not player:prohibitDiscard(id)
    end)
    if #ids ~= 1 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = lunxiong.name,
        pattern = "false",
        prompt = "#lunxiong-invoke:::"..(player:getMark(lunxiong.name) + 1),
        cancelable = true,
      })
    else
      local cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = lunxiong.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#lunxiong-invoke:::"..(player:getMark(lunxiong.name) + 1),
        cancelable = true,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    room:setPlayerMark(player, lunxiong.name, Fk:getCardById(id).number)
    room:throwCard(id, lunxiong.name, player, player)
    if not player.dead then
      player:drawCards(3, lunxiong.name)
    end
  end,
}

lunxiong:addEffect(fk.Damage, lunxiong_spec)
lunxiong:addEffect(fk.Damaged, lunxiong_spec)

return lunxiong
