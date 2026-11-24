#include "pch.h"
#include "server/rpc-lua/rpc-wire.h"
#include <unistd.h>

using namespace JsonRpc;
using namespace RpcWire;
namespace asio = boost::asio;
using Bytes = std::vector<unsigned char>;
using namespace std::literals;

static Bytes bytes(std::string_view value) {
  return {value.begin(), value.end()};
}

// A pipe exercises the production encoder, including writes larger than the
// kernel pipe capacity. The reader deliberately uses small chunks.
static Bytes encode(const std::function<void(asio::posix::stream_descriptor &)> &send) {
  int fds[2];
  if (pipe(fds) != 0) throw std::runtime_error("pipe failed");
  asio::io_context ctx;
  asio::posix::stream_descriptor writer(ctx, fds[1]);
  Bytes output;
  std::thread reader([&] {
    unsigned char chunk[1024];
    ssize_t size;
    while ((size = read(fds[0], chunk, sizeof(chunk))) > 0)
      output.insert(output.end(), chunk, chunk + size);
    close(fds[0]);
  });
  try { send(writer); } catch (...) { writer.close(); reader.join(); throw; }
  writer.close();
  reader.join();
  return output;
}

int main(int argc, char **argv) {
  int failures = 0;
  auto check = [&](bool ok, const char *name) {
    std::cout << (ok ? "PASS " : "FAIL ") << name << '\n';
    failures += !ok;
  };
  const auto first = bytes("\xa4\x18\x64\x43" "2.0" "\x18\x65\x45" "First" "\x18\x68\x01\x18\x66\x81\x45" "Alpha"sv);
  const auto second = bytes("\xa4\x18\x64\x43" "2.0" "\x18\x65\x45" "Other" "\x18\x68\x02\x18\x66\x81\x45" "Bravo"sv);
  bool splits = true;
  for (size_t n = 0; n < first.size(); ++n) {
    Bytes input(first.begin(), first.begin() + n), storage;
    const auto prefix = input;
    JsonRpcPacket pkt;
    splits &= takeRpcPacket(input, storage, pkt) == CBOR_DECODER_NEDATA && input == prefix;
    input.insert(input.end(), first.begin() + n, first.end());
    splits &= takeRpcPacket(input, storage, pkt) == CBOR_DECODER_FINISHED && input.empty() &&
      pkt.method == "First" && pkt.id == 1 && std::get<std::string_view>(pkt.param1) == "Alpha";
  }
  check(splits, "every fragmentation boundary");
  Bytes input = first, aStorage, bStorage;
  input.insert(input.end(), second.begin(), second.end());
  JsonRpcPacket a, b;
  const bool aOk = takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED;
  const bool bOk = takeRpcPacket(input, bStorage, b) == CBOR_DECODER_FINISHED;
  check(aOk && bOk && input.empty() && a.method == "First" && b.method == "Other" &&
    std::get<std::string_view>(a.param1) == "Alpha" && std::get<std::string_view>(b.param1) == "Bravo",
    "coalesced packets retain outer string views during nested dispatch");
  const std::string payload(1024 * 1024, 'P');
  auto request = JsonRpc::request("Large", std::numeric_limits<int64_t>::min(),
    std::numeric_limits<int64_t>::max(), payload, 17);
  request.param_count = 5;
  request.param4 = std::numeric_limits<int>::min();
  request.param5 = true;
  input = encode([&](auto &writer) { sendRequest(writer, request); });
  check(takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && input.empty() && a.id == 17 &&
    a.method == "Large" && a.param_count == 5 && std::get<int64_t>(a.param1) == std::numeric_limits<int64_t>::min() &&
    std::get<int64_t>(a.param2) == std::numeric_limits<int64_t>::max() && std::get<std::string_view>(a.param3) == payload &&
    std::get<int>(a.param4) == std::numeric_limits<int>::min() && std::get<bool>(a.param5),
    "complete large pipe write and signed integer limits");
  int stalled[2];
  if (pipe(stalled) != 0) throw std::runtime_error("pipe failed");
  asio::io_context stalledCtx;
  asio::posix::stream_descriptor stalledReader(stalledCtx, stalled[0]), stalledWriter(stalledCtx, stalled[1]);
  char byte;
  bool readTimedOut = false, writeTimedOut = false;
  try { readRpcBytes(stalledReader, asio::buffer(&byte, 1), 30ms); }
  catch (const boost::system::system_error &e) { readTimedOut = e.code() == asio::error::timed_out; }
  try { writeRpcBytes(stalledWriter, asio::buffer(payload), 30ms); }
  catch (const boost::system::system_error &e) { writeTimedOut = e.code() == asio::error::timed_out; }
  check(readTimedOut && writeTimedOut, "idle worker read and backpressured write time out");
  auto error = responseError(request, "internal_error", "synthetic"s);
  input = encode([&](auto &writer) { sendError(writer, error); });
  check(takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.error.code == -32603 &&
    a.id == 17 && a.error.message == "Internal error" && input.empty(), "negative error code round trip");
  const RpcMethodMap methods{{"Large", [](const JsonRpcPacket &) -> std::pair<bool, JsonRpcParam> {
    throw std::runtime_error("owned exception data");
  }}};
  auto exception = handleRequest(methods, request);
  check(exception && exception->error.code == -32603 && std::get<std::string>(exception->error.data) == "owned exception data",
    "exception message has owned storage");
  a.reset();
  check(a.id == -1 && a.param_count == 0 && a.method.empty() && a.error.code == 0 && a.error.message.empty() &&
    std::holds_alternative<std::nullptr_t>(a.param5) && std::holds_alternative<std::nullptr_t>(a.result), "packet reset");
  const std::vector<Bytes> invalid = {
    bytes("\xa2\x18\x64\x43" "2.0" "\x18\x64\x43" "2.0"sv), // duplicate key
    bytes("\xa2\x18\x64\x43" "1.0" "\x18\x68\x01"sv), // version
    bytes("\xa2\x18\x64\x43" "2.0" "\x18\x68\x00"sv), // invalid id
    bytes("\xa2\x18\x64\x43" "2.0" "\x18\x65\x5a\x02\x00\x00\x00"sv), // oversized
    bytes("\xa3\x18\x64\x43" "2.0" "\x18\x65\x41x\x18\x66\x81\x1b\xff\xff\xff\xff\xff\xff\xff\xff"sv), // uint overflow
    bytes("\xa3\x18\x64\x43" "2.0" "\x18\x65\x41x\x18\x66\x81\x80"sv), // unsupported param
  };
  bool rejects = true;
  for (const auto &frame : invalid) {
    input = frame;
    rejects &= takeRpcPacket(input, aStorage, a) == CBOR_DECODER_ERROR && input == frame;
  }
  check(rejects, "malformed keys, version, ID, size and parameter rejected");
  std::array<std::vector<int>, 8> ids;
  std::vector<std::thread> workers;
  for (auto &group : ids) workers.emplace_back([&group] {
    for (int i = 0; i < 2000; ++i) group.push_back(JsonRpc::request("Test").id);
  });
  for (auto &worker : workers) worker.join();
  std::set<int> unique;
  for (auto &group : ids) unique.insert(group.begin(), group.end());
  check(unique.size() == 16000, "concurrent request IDs are unique");
  if (argc == 2) {
    std::ifstream fixture(argv[1], std::ios::binary);
    input.assign(std::istreambuf_iterator<char>(fixture), {});
    bool luaOk = takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.method == "hello" &&
      a.id == -1 && std::get<std::string_view>(a.param1) == "world";
    luaOk &= takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.id == 11 && a.method.empty();
    luaOk &= takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.id == 12 && a.method.empty();
    luaOk &= takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.id == 13 && a.error.code == -32603;
    luaOk &= takeRpcPacket(input, aStorage, a) == CBOR_DECODER_FINISHED && a.id == 14 && a.param_count == 6 &&
      std::get<std::string_view>(a.param5) == "five" && input.empty();
    check(luaOk, "pinned Lua encoder hello, void response, omitted result, nested error and print");
  }
  return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
