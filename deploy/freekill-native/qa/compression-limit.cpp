#include "pch.h"
#include "core/util.h"

int main() {
  constexpr size_t limit = 8 * 1024 * 1024;
  const std::string payload(limit, 'a');
  if (qUncompress_std(qCompress_std(payload)) != payload) {
    std::cerr << "FAIL valid boundary round trip\n";
    return 1;
  }
  if (qUncompress_std(qCompress_std("")).size() != 0) {
    std::cerr << "FAIL empty round trip\n";
    return 1;
  }
  const auto oversized = qCompress_std(std::string(limit + 1, 'a'));
  try {
    const auto decoded = qUncompress_std(oversized);
    std::cerr << "FAIL oversized valid zlib payload accepted: " << decoded.size() << " bytes\n";
    return 1;
  } catch (const std::runtime_error &) {}
  try {
    qUncompress_std("x");
    std::cerr << "FAIL truncated compression header accepted\n";
    return 1;
  } catch (const std::runtime_error &) {}
  try {
    auto invalid = qCompress_std("synthetic");
    invalid.pop_back();
    qUncompress_std(invalid);
    std::cerr << "FAIL truncated compressed body accepted\n";
    return 1;
  } catch (const std::runtime_error &) {}
  try {
    qUncompress_std(std::string("\0\0\0\0x", 5));
    std::cerr << "FAIL invalid empty payload accepted\n";
    return 1;
  } catch (const std::runtime_error &) {}
  try {
    qUncompress_std(qCompress_std("synthetic") + "trailing");
    std::cerr << "FAIL trailing compressed bytes accepted\n";
    return 1;
  } catch (const std::runtime_error &) {}
  std::cout << "PASS decompression bound, valid round trips and truncated input rejection\n";
}
