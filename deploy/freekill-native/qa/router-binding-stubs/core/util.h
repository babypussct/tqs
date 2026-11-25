#pragma once
inline std::string qCompress_std(const std::string_view &data, int = -1) { return std::string(data); }
inline std::string qUncompress_std(const std::string_view &data) { return std::string(data); }
