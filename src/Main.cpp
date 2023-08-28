#include <iostream>
#include <memory>

// #include "ClangTidyWarnings.h"

int main(int argc, const char** argv) {
    // ClangTidyWarnings warning;
    // warning.BadCode();

    // NOLINTBEGIN

    const char str[] = "This is bad code";
    std::cout << str << std::endl;

    // NOLINTEND

    try {
        throw(1);
    }
    catch (int error) {
    }

    return 0;
}
