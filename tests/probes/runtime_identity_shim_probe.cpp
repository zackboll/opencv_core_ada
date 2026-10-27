// Compile the actual production shim so bounded controls exercise its exact
// private protocol implementation, without exporting test hooks in production.
#include "../../cpp/opencv_core_shim.cpp"
#include <iostream>

static void check(bool value, const char *message) {
    if (!value) throw std::runtime_error(message);
}

using Query = opencv_core_status (*)(char *, uint64_t, uint64_t *, uint64_t *);

static void qualify(Query query, const cv::String &native) {
    uint64_t required = 91, written = 92;
    auto bad = [](opencv_core_status status) {
        check(status == OPENCV_CORE_ERROR_INVALID_ARGUMENT, "invalid argument status");
        check(std::strlen(opencv_core_last_error_message()) != 0, "failure diagnostic");
    };
    bad(query(nullptr, 0, nullptr, &written));
    check(written == 0, "null required initializes written");
    bad(query(nullptr, 0, &required, nullptr));
    check(required == 0, "null written initializes required");
    bad(query(nullptr, 0, &required, &required));
    check(required == 0, "aliased count rejected and initialized");
    required = written = 91;
    bad(query(nullptr, 1, &required, &written));
    check(required == 0 && written == 0, "invalid pointer pair initializes counts");
    char sentinel = '!';
    bad(query(&sentinel, 0, &required, &written));
    check(required == 0 && written == 0 && sentinel == '!', "nonnull zero capacity");
    for (uint64_t cap : {UINT64_MAX, UINT64_MAX - 1}) {
        bad(query(&sentinel, cap, &required, &written));
        check(required == 0 && written == 0 && sentinel == '!', "capacity overflow");
        bad(query(nullptr, cap, &required, &written));
    }
    check(query(nullptr, 0, &required, &written) == 0, "query succeeds after failures");
    check(required == native.size() && written == 0, "query exact payload length");
    const auto length = required;
    std::vector<char> buffer(static_cast<size_t>(length + 2), '!');
    for (uint64_t cap : {uint64_t(1), length}) {
        required = written = 91;
        bad(query(buffer.data(), cap, &required, &written));
        check(required == length && written == 0, "insufficient capacity counts");
        check(std::all_of(buffer.begin(), buffer.end(), [](char c) { return c == '!'; }),
              "one-byte-short and insufficient copies leave entire buffer untouched");
    }
    check(query(buffer.data(), length + 1, &required, &written) == 0, "exact capacity");
    check(required == length && written == length && buffer[length] == '\0' &&
          buffer[length + 1] == '!', "payload/NUL counts and bounds");
    check(std::memcmp(buffer.data(), native.data(), native.size()) == 0, "native byte parity");
    check(std::strlen(opencv_core_last_error_message()) == 0, "success clears diagnostic");
    const auto saved = buffer;
    for (int i = 0; i < 20; ++i) {
        uint64_t r, w;
        check(opencv_core_native_build_information(nullptr, 0, &r, &w) == 0, "interleave build");
        check(opencv_core_native_version_string(nullptr, 0, &r, &w) == 0, "interleave version");
        cv::Mat temporary = cv::Mat::ones(3, 4, CV_8U);
        check(cv::sum(temporary)[0] == 12, "unrelated native operation");
    }
    check(buffer == saved, "caller storage survives later calls and finalization");
}

// Synthetic length only: overflow is rejected before data() is consulted.
struct Oversized {
    uint64_t size() const { return UINT64_MAX; }
    const char *data() const { throw std::runtime_error("must not access oversized data"); }
};

int main() {
    qualify(opencv_core_native_version_string, cv::getVersionString());
    qualify(opencv_core_native_build_information, cv::getBuildInformation());
    for (uint64_t limit : {uint64_t(1), uint64_t(8), uint64_t(255), UINT64_MAX}) {
        check(runtime_text_length_fits(limit - 1, limit), "last safe payload");
        check(!runtime_text_length_fits(limit, limit), "NUL addition overflow rejected");
    }
    char buffer[32];
    std::memset(buffer, '!', sizeof(buffer));
    uint64_t r = 91, w = 92;
    check(runtime_text([] { return cv::String(); }, nullptr, 0, &r, &w) == 0 &&
          r == 0 && w == 0, "empty native payload query");
    check(runtime_text([] { return cv::String(); }, buffer, 1, &r, &w) == 0 &&
          r == 0 && w == 0 && buffer[0] == '\0' && buffer[1] == '!',
          "empty native payload still writes one NUL");
    std::memset(buffer, '!', sizeof(buffer));
    check(runtime_text([] { return Oversized{}; }, buffer, sizeof(buffer), &r, &w) ==
          OPENCV_CORE_ERROR_INVALID_ARGUMENT && r == 0 && w == 0, "oversized length");
    auto failure = [&](auto provider, opencv_core_status expected) {
        r = w = 91;
        check(runtime_text(provider, buffer, sizeof(buffer), &r, &w) == expected,
              "native exception translated");
        check(r == 0 && w == 0 && std::strlen(opencv_core_last_error_message()) > 0,
              "exception output initialization and diagnostic");
        check(std::all_of(std::begin(buffer), std::end(buffer), [](char c) { return c == '!'; }),
              "exception never publishes partial text");
    };
    failure([]() -> cv::String { throw std::bad_alloc(); }, OPENCV_CORE_ERROR_STD);
    failure([]() -> cv::String { throw std::runtime_error("native text control"); },
            OPENCV_CORE_ERROR_STD);
    failure([]() -> cv::String { CV_Error(cv::Error::StsError, "text control"); },
            OPENCV_CORE_ERROR_OPENCV);
    failure([]() -> cv::String { throw 7; }, OPENCV_CORE_ERROR_UNKNOWN);
    const cv::String bytes("line1\n\xc3\xa9\0tail\n", 14);
    check(runtime_text([&]() -> const cv::String & { return bytes; }, buffer,
                       sizeof(buffer), &r, &w) == 0, "success after native exceptions");
    check(r == bytes.size() && w == r && buffer[r] == '\0' &&
          std::memcmp(buffer, bytes.data(), bytes.size()) == 0,
          "multiline/non-ASCII/embedded-NUL byte preservation");
    std::cout << "runtime identity actual-shim parity/ABI/exception controls PASS: "
              << cv::getVersionString() << '\n';
}