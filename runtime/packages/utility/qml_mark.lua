-- 在脸上显示花色（如老宝烈弓）
-- 传入值：suit数组（不是suit string）
Fk:addQmlMark{
  name = "suits",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    return table.concat(table.map(value, function(suit)
      return Fk:translate(Card.getSuitString({ suit = suit }, true))
    end), "")
  end,
}
-- 在脸上显示角色武将名（若有副将，改为显示位置）
-- 传入值：角色ID
Fk:addQmlMark{
  name = "chara",
  how_to_show = function(_, value)
    if type(value) == "string" then value = tonumber(value) end --- 实际访问的时候这里会出string
    if not value or type(value) ~= "number" then return " " end
    local player = Fk:currentRoom():getPlayerById(value)
    if (not player) or (not player.general) or (player.general == "") then return " " end
    local ret = player.general
    if player.deputyGeneral and player.deputyGeneral ~= "" then
      ret = "seat#" .. player.seat
    end
    return Fk:translate(ret)
  end,
}
-- 记录多名角色，脸上显示数量，点击查看角色信息（若后继以$开头则仅自己可见）
-- 传入值：角色ID
Fk:addQmlMark{
  name = "player",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    return tostring(#value)
  end,
  qml = function(name, value, player)
    if Self:isBuddy(player) or not string.startsWith(name, "@[player]$") then
      return {
        url = "packages/utility/qml/PlayerBox.qml",
        prop = {
          name = name,
          value = value,
        },
      }
    end
    return {}
  end,
}
-- 在脸上显示类别
-- 传入值：card type数组（不是card string）
Fk:addQmlMark{
  name = "cardtypes",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    local types = {}
    if table.contains(value, 1) then
      table.insert(types, Fk:translate("basic_char"))
    end
    if table.contains(value, 2) then
      table.insert(types, Fk:translate("trick_char"))
    end
    if table.contains(value, 3) then
      table.insert(types, Fk:translate("equip_char"))
    end
    return table.concat(types, " ")
  end,
}

--仅自己可见的mark
--额外的，后继带$前缀为武将牌堆，后继带&前缀为卡牌牌堆，此时公开逻辑变为是否能点击展示这些卡牌；带:前缀的为说明（DetailBox）
Fk:addQmlMark{
  name = "private",
  qml = function(name, value, player)
    if not (value.players == nil and Self == player) and not (value.players and table.contains(value.players, Self.id)) then
      return nil
    end

    local url, uri, typeName, prop
    local val = value.value
    if string.startsWith(name, "@[private]$") then
      uri = "LunarLtk.Pages.InfoPopups"
      typeName = "ViewPile"

      local key = "ids"
      if type(val[1]) == "string" then key = "cardNames" end
      prop = { [key] = val }
    elseif string.startsWith(name, "@[private]&") then
      uri = "LunarLtk.Pages.InfoPopups"
      typeName = "ViewGeneralPile"
      prop = { cardNames = val }
    elseif string.startsWith(name, "@[private]:") then
      if type(val) == "string" then --兼容单个字符串的情况
        val = { val }
      end
      url = "packages/utility/qml/DetailBox.qml"
      prop = {
        name = name,
        value = val,
      }
    end

    return {
      uri = uri,
      name = typeName,
      url = url,

      prop = prop,
    }
  end,
  how_to_show = function(name, value, player)
    if type(value) ~= "table" then return " " end
    local val = value.value ---@type string|table
    local visible = (value.players == nil and Self == player) or (value.players and table.contains(value.players, Self.id))
    if table.contains({"$", "&", ":"}, name[11]) and type(val) == "table" then -- string.startsWith(name, "@[private]$") or string.startsWith(name, "@[private]&") or string.startsWith(name, "@[private]:") then
      return tostring(#val)
    elseif visible then
      if type(val) == "string" then
        return Fk:translate(val)
      else
        return table.concat(table.map(val, Util.TranslateMapper), " ")
      end
    end
    return " "
  end,
}

-- 详细描述mark: @[:]xxxx
-- 翻译储存值，值可以是字符串，或者字符串表
-- 若储存字符串，标记显示该字符串的翻译，若储存字符串表，标记显示表元素个数
-- 例：手杀曹嵩亿金
Fk:addQmlMark{
  name = ":",
  how_to_show = function(name, value)
    if type(value) == "string" then
      return Fk:translate(value)
    elseif type(value) == "table" then
      return tostring(#value)
    end
    return " "
  end,
  qml = function(name, value, player)
    local val = value
    if type(value) == "string" then--兼容单个字符串的情况
      val = { value }
    end
    return {
      url = "packages/utility/qml/DetailBox.qml",
      prop = {
        name = name,
        value = val,
      },
    }
  end,
}

-- 翻译标记名mark: @[desc]xxxx
-- 标记qml显示 :xxxx 的翻译（xxxx为标记名，不含“@[desc]”）
-- 标记外部显示此标记的个数，若为1个则仅显示标记名
-- 可用于需要解释作用的标记，如延时效果，例：新服神张飞神裁
Fk:addQmlMark{
  name = "desc",
  how_to_show = function(name, value)
    local number = tonumber(value)
    if number and number > 1 then
      return value
    end
    return " "
  end,
  qml = function(name, value, player)
    return {
      url = "packages/utility/qml/DescMarkBox.qml",
      prop = {
        name = name,
      },
    }
  end,
}

-- 数组型通用标记：@[list]xxx
-- 需要基于最新特性，在数组中直接存储相关实例才可使用
-- core也需要做出调整
-- 遵照故事带个$表示隐藏
Fk:addQmlMark{
  name = "list",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    return tostring(#value)
  end,
  qml = function(name, value, player)
    if Self:isBuddy(player) or not name:startsWith("@[list]$") then
      return {
        url = "packages/utility/qml/ListMarkBox.qml",
        prop = {
          name = name,
          value = value,
        },
      }
    end
    return {}
  end,
}

Fk:addQmlMark{
  name = "mou__xieli",
  qml = function(name, value, player)
    return {
      url = "packages/utility/qml/XiejiBox.qml",
      prop = {
        name = name,
        value = value,
      },
    }
  end,
  how_to_show = function(name, value, player)
    if type(value) == "table" then
      local target = Fk:currentRoom():getPlayerById(value[1])
      if target then return Fk:translate("seat#" .. target.seat) end
    end
    return " "
  end,
}
