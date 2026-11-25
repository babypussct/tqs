#pragma once
class Cbor {
public:
  static inline std::function<void()> beforeEncode;
  static inline thread_local int lastRequestId;
  static std::string encodeArray(std::initializer_list<std::variant<int, unsigned int, int64_t, uint64_t, std::string_view, const char *, bool>> items) {
    lastRequestId = std::get<int>(*items.begin());
    if (beforeEncode) beforeEncode();
    for (const auto &item : items) if (const auto *s = std::get_if<std::string_view>(&item)) return std::string(*s);
    return {};
  }
};
